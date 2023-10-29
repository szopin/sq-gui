import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Nemo.Configuration 1.0
import '../src'

Page{
    id: page
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
    property string atttext
    property int begindex: 0
    property int okindex: 0
    property bool overwrite: false

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
            if(overwrite){
                getfile("/home/defaultuser/decrypt.dec");
                putfile('/home/defaultuser/decrypt.dec', "");
                overwrite = false;
            }
            if(okindex > 0){
                list.model.setProperty(okindex -1, "done", true);
                okindex = 0;
            }
        }
        onError: {
            error = true
            if(overwrite){
                getfile("/home/defaultuser/decrypt.dec");
                putfile('/home/defaultuser/decrypt.dec', "");
                overwrite = false;
            }
        }
    }


    function findb64att(body, mod, index){
        var starter = body.indexOf('filename=');

        if (starter > 0){

            var re = /filename=\"(.*)\"/

            var match = re.exec(body.slice(starter, starter + 256))

            var bound = body.slice(0, starter).lastIndexOf("\n--") ;

            var re2 = /\n--(.*)\r?\n/
            var match2 = re2.exec(body.slice(bound, bound + 100))

            var endpart = match2[1]// '--' + match2[1]// + '--'
            var endindex = body.slice(starter).indexOf(endpart)

            var basoffset = body.slice(starter + match[1].length).indexOf('\r\n\r\n') + 4
            var b64true = body.slice(0, bound + starter + basoffset + match[1].length).indexOf('Content-Transfer-Encoding: base64');
            var bas64 = body.slice(starter  + match[1].length +basoffset, starter    + endindex -4)
            if(mod==2){
                putfile('/home/defaultuser/' + match[1], bas64);
                list.model.setProperty(index, "done", true);
            }
            bas64 = bas64.replace(/(\r)/gm, '');

            if(mod==1){
                okindex = index+1;
                putfile('/home/defaultuser/b64.tmp', bas64);
                engine.exec("base64 -d /home/defaultuser/b64.tmp > /home/defaultuser/" + match[1], true);
            }

            atttext = match[1];
            if(mod==0){
                list.model.append({ atttext: atttext, done: false, b64: b64true, begindex: begindex});
                begindex += starter + endindex -4
                findb64att(body.slice(starter + endindex -4), 0)
            }
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
        return // xhr.responseText;
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

    DockedPanel {
        id: panel
        dock: Dock.Bottom
        width: parent.width
        height: (Theme.itemSizeSmall) * list.model.count + Theme.paddingSmall
        SilicaListView {
            id: list
            anchors.fill: parent
            model: ListModel { id: model }
            delegate: ListItem {
                width: parent.width
                Row {
                    spacing: Theme.paddingSmall
                    width: parent.width
                    height: Theme.itemSizeSmall +Theme.paddingSmall
                    Label {
                        id: fname
                        width: parent.width *0.9
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        text: atttext
                    }
                    Label {
                        id: chkbx
                        width: parent.width *0.1
                        anchors.verticalCenter: parent.verticalCenter
                        text: !done ? "◻" : "☑"
                    }
                }
                onClicked: {
                    if(b64 > 0){
                        findb64att(filetext.slice(begindex), 1, index);
                    } else {
                        findb64att(filetext.slice(begindex), 2, index);
                    }
                }
            }

        }
    }

    SilicaFlickable {
        id: view
        anchors.fill: parent
        anchors.bottomMargin: panel.visibleSize
        clip:  panel.expanded
        contentHeight: lab.height

        TextArea{

            id: lab

            clip: panel.expanded
            color: Theme.primaryColor
            text: filetext.slice(0,4096) // getfile(Qt.application.arguments[1])
        }
        VerticalScrollDecorator {}

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
            MenuItem{
                visible: lab.text.indexOf('filename="') > 0
                text: qsTr('Attachment(s)')
                onClicked: {
                    begindex = 0;
                    list.model.clear();
                    findb64att(filetext, 0);

                    panel.open = !panel.open; //findb64att(filetext);

                }
            }
            MenuItem {
                text: qsTr('Decrypt - passwordless')
                onClicked: {
                    overwrite = true;
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
                        passField.focus = false;
                        overwrite = true;
                        engine.exec('expect -c "spawn sq --force decrypt --recipient-file ' + keypath + ' ' + filepath + ' -o /home/defaultuser/decrypt.dec; expect -re \\".*password.*\\"; send \\"' + text + '\\n\\"; expect eof"',true);

                        mainPullDownMenu.close()
                    }
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

}

