import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Nemo.Configuration 1.0
import '../src'

Page{
    property var filetext
    property var filepath
    property var keypath
    property var lkey
    objectName: 'result'

    property string output
    property string errors
    property bool error: false
    property bool errorMode: false
    property string name

    property variant offsets: []
    property variant columns: []

    ConfigurationGroup {
        id: mainConfig
        path: "/apps/sq-gui"
        ConfigurationValue {
            id: lkeypath
            key: "/apps/sq-gui/lkey"
        }
    }
    Connections {
        target: cengine
        onOutput: {
            
            getfile("/home/defaultuser/decrypt.dec");
            putfile('/home/defaultuser/decrypt.dec', "");
        }
        onError: {
            error = true
            
            getfile("/home/defaultuser/decrypt.dec");
            putfile('/home/defaultuser/decrypt.dec', "");
        }

        
    }

    function getfile(url){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                
                filetext = xhr.responseText
            }
        }
        xhr.send();
        return xhr.responseText;
    }
    function putfile(url, body){
        var xhr = new XMLHttpRequest;
        xhr.open("PUT", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {

            }
        }
        xhr.send(body);
        return xhr.responseText;
    }
    
    onStatusChanged: {
        if (status === PageStatus.Active){
            pageStack.pushAttached(Qt.resolvedUrl("encrypt.qml"));
        }
    }
    allowedOrientations: Orientation.All

    property CommandEngine engine

    SilicaFlickable {
        id: list
        anchors.fill: parent
        contentHeight: lab.height
        //   clip: true
        Item{
            anchors.fill: parent
            height: lab.contentHeight
            VerticalScrollDecorator {}

            Text{

                id: lab
                anchors.fill: parent

                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                color: Theme.primaryColor
                anchors.verticalCenter: parent.verticalCenter
                text: filetext // getfile(Qt.application.arguments[1])
                //   truncationMode: TruncationMode.Fade
            }
        }

        PullDownMenu {
            id: mainPullDownMenu
            MenuItem{
                text: qsTr('Copy to clipboard')
                onClicked: Clipboard.text = filetext
            }
            MenuItem{
                text: qsTr('Select file')
                onClicked: pageStack.push(filePicker2);
            }
            MenuItem{
                text: keypath ? keypath : qsTr('Select private key')
                onClicked: pageStack.push(filePicker);
            }
            MenuItem {
                text: qsTr('Decrypt - passwordless')
                onClicked: {
                    engine.exec('expect -c "spawn sq --force decrypt --recipient-file ' + keypath + ' ' + filepath + ' -o /home/defaultuser/decrypt.dec; expect eof"',true);
                }
            }
            Item {
                height: Theme.itemSizeMedium
                width: parent.width
                PasswordField {
                    id: passField
                    width: parent.width
                    height: Theme.itemSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    placeholderText: qsTr("Password")
                    EnterKey.enabled: text.length > 0
                    EnterKey.onClicked: {
                        passField.focus = false
                        engine.exec('expect -c "spawn sq --force decrypt --recipient-file ' + keypath + ' ' + filepath + ' -o /home/defaultuser/decrypt.dec; expect -re \\".*password.*\\"; send \\"' + text + '\\n\\"; expect eof"',true);

                        mainPullDownMenu.close()
                    }
                }
            }
        }
    }

    Component {
        id: filePicker
        FilePickerPage {
            title: qsTr('Select recipient key');
            nameFilters: [ '*.pgp', '*.gpg', '*.asc' ]
            onSelectedContentPropertiesChanged: {
                keypath = selectedContentProperties.filePath
                mainConfig.setValue("lkey", keypath);
            }
        }
    }
    Component {
        id: filePicker2
        FilePickerPage {
            title: qsTr('Select encrypted file');
            nameFilters: [ '*.*']
            onSelectedContentPropertiesChanged: {
                filepath = selectedContentProperties.filePath
                filetext = getfile(filepath);
            }
        }
    }
    Component.onCompleted: {
        lkey = mainConfig.value("lkey", "-1");
        if (lkey != -1) keypath = lkey;
        if(Qt.application.arguments[1]){
            filepath = Qt.application.arguments[1]
            filetext = getfile(Qt.application.arguments[1]);
        }
        
    }
}
