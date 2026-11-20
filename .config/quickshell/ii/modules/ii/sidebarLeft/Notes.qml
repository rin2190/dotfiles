import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property string notesDir: FileUtils.trimFileProtocol(Directories.documents) + "/Notes"
    property string imagesDir: notesDir + "/imagenes"
    property var blocks: []
    property var pendingImages: []
    readonly property string saveScript: 'mkdir -p "$(dirname "$1")" "$3" && printf "%s" "$2" > "$1" && shift 3 && while [ $# -ge 2 ]; do cp "$1" "$2"; shift 2; done'

    function sendBlock(text) {
        const trimmed = text.trim();
        if (trimmed.length === 0 && root.pendingImages.length === 0) return;
        root.blocks = [...root.blocks, { text: trimmed, images: root.pendingImages }];
        root.pendingImages = [];
        blockList.positionViewAtEnd();
    }

    function addPending(path) {
        root.pendingImages = [...root.pendingImages, path];
    }

    function removePending(index) {
        root.pendingImages = root.pendingImages.filter((_, i) => i !== index);
    }

    function writeNotes(list, prefix) {
        if (list.length === 0) return;
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        let parts = [];
        let copies = [];
        let n = 0;
        for (const b of list) {
            if (b.text.length > 0) parts.push(b.text);
            for (const img of b.images) {
                n += 1;
                const name = "imagen_" + stamp + "_" + n + ".png";
                parts.push("![imagen " + n + "](imagenes/" + name + ")");
                copies.push(img, root.imagesDir + "/" + name);
            }
        }
        saveProc.command = ["bash", "-c", root.saveScript, "_", root.notesDir + "/" + prefix + "_" + stamp + ".md", parts.join("\n\n"), root.imagesDir].concat(copies);
        saveProc.running = true;
    }

    function saveBlock(index) {
        root.writeNotes([root.blocks[index]], "nota");
    }

    function saveAll() {
        root.writeNotes(root.blocks, "notas");
    }

    function handleInput(inputText) {
        if (inputText.startsWith("/")) {
            const command = inputText.split(" ")[0].substring(1);
            if (command === "clear") {
                root.blocks = [];
                root.pendingImages = [];
            } else if (command === "save") {
                root.saveAll();
            } else {
                root.sendBlock(Translation.tr("Comando desconocido: ") + command);
            }
        } else {
            root.sendBlock(inputText);
        }
    }

    Process {
        id: saveProc
    }

    Process {
        id: decodeClipboardProc
        property string outputPath: ""
        function decodeEntry(entry: string) {
            outputPath = "/tmp/notes_clip_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".png";
            decodeClipboardProc.command = ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(entry)}' | ${Cliphist.cliphistBinary} decode > '${outputPath}'`];
            decodeClipboardProc.running = true;
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) root.addPending(outputPath);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        ListView {
            id: blockList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.blocks
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: blockList.width
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2
                implicitHeight: row.implicitHeight + 16

                RowLayout {
                    id: row
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            visible: modelData.text.length > 0
                            text: modelData.text
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnLayer2
                        }

                        Repeater {
                            model: modelData.images
                            delegate: Image {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 160
                                fillMode: Image.PreserveAspectFit
                                source: "file://" + modelData
                            }
                        }
                    }

                    RippleButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colLayer3
                        onClicked: root.saveBlock(index)
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "save"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer3
                        }
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4
            visible: root.pendingImages.length > 0

            Repeater {
                model: root.pendingImages
                delegate: Image {
                    required property int index
                    required property var modelData
                    width: 56
                    height: 56
                    fillMode: Image.PreserveAspectCrop
                    source: "file://" + modelData

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.removePending(index)
                    }
                }
            }
        }

        Rectangle {
            id: inputPill
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(45, inputRow.implicitHeight + 12)
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2

            RowLayout {
                id: inputRow
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                TextArea {
                    id: input
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(120, implicitHeight)
                    wrapMode: TextEdit.Wrap
                    placeholderText: Translation.tr("Escribe una nota (Enter envía, Shift+Enter nueva línea, Ctrl+V pega captura)")
                    color: Appearance.colors.colOnLayer1
                    background: null
                    Keys.onPressed: event => {
                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                            const entry = Cliphist.entries[0];
                            if (/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry)) {
                                decodeClipboardProc.decodeEntry(entry);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                input.insert(input.cursorPosition, "\n");
                            } else {
                                const text = input.text;
                                input.clear();
                                root.handleInput(text);
                            }
                            event.accepted = true;
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 34
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.normal
                    colBackground: Appearance.colors.colPrimary
                    onClicked: {
                        const text = input.text;
                        input.clear();
                        root.handleInput(text);
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "send"
                        iconSize: 18
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            ApiCommandButton {
                buttonText: "/clear"
                onClicked: {
                    root.blocks = [];
                    root.pendingImages = [];
                }
            }
        }
    }
}
