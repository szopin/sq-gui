import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Sailfish.Pickers 1.0
import '../src'

Page{
    id: encpage

    property var rkeypath: ""
    property var rkey
    property var filetexta
    
    function getfilee(url){
        var xhr = new XMLHttpRequest;
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                
                filetexta = xhr.responseText
            }
        }
        xhr.send();
        return xhr.responseText;
    }
    
    function putfilee(url, body){
        var xhr = new XMLHttpRequest;
        xhr.open("PUT", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                

            }
        }
        xhr.send(body);
        return xhr.responseText;
    }
    
    Connections {
        target: cengine
        onOutput: {

            getfilee("/home/defaultuser/encrypt.enc");
            putfilee('/home/defaultuser/encrypt.dec', "");
            putfilee('/home/defaultuser/encrypt.enc', "");
        }
        onError: {

            getfilee("/home/defaultuser/encrypt.enc");
            putfilee('/home/defaultuser/encrypt.dec', "");
            putfilee('/home/defaultuser/encrypt.enc', "");
        }
    }
    
    ConfigurationGroup {
        id: mainConfig
        path: "/apps/sq-gui"
        ConfigurationValue {
            id: rrkeypath
            key: "/apps/sq-gui/rkey"
        }
    }
    SilicaFlickable{
        id: flicka
        anchors.fill: parent

        PullDownMenu{
            MenuItem{
                text: rkeypath ? rkeypath : qsTr('Select public key')
                
                onClicked: pageStack.push(filePicker);
                
            }
            MenuItem{
                text: qsTr('Copy to clipboard')
                onClicked: Clipboard.text = filetexta
            }

            MenuItem{
                visible: rkeypath != ""
                text: qsTr("Encrypt")
                onClicked: {
                    putfilee('/home/defaultuser/encrypt.dec', postbody.text);
                    engine.exec("sq --force encrypt --recipient-file " + rkeypath  + " /home/defaultuser/encrypt.dec -o /home/defaultuser/encrypt.enc", true);
                    putfilee('/home/defaultuser/encrypt.dec', "");
                }

            }
        }
        PageHeader {
            id: pageHeader
            title:  qsTr("Enter post")
        }
        TextArea {
            id: postbody
            text: filetexta
            anchors.top: pageHeader.bottom
            width: parent.width

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            softwareInputPanelEnabled: true
            placeholderText: qsTr("Body");


        }

    }
    Component.onCompleted: {
        rkey = mainConfig.value("rkey", "-1");
        console.log(rkey);
        if (rkey != -1) rkeypath = rkey;
    }
    
    Component {
        id: filePicker
        FilePickerPage {
            title: qsTr('Select recipient key');
            nameFilters: [ '*.pgp', '*.gpg', '*.asc' ]
            onSelectedContentPropertiesChanged: {
                rkeypath = selectedContentProperties.filePath
                mainConfig.setValue("rkey", rkeypath);
                console.log(rkeypath)
            }
        }
    }
    
}
