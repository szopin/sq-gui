import QtQuick 2.0
import Sailfish.Silica 1.0
import 'pages'
import 'cover'
import 'src'

ApplicationWindow
{
    id: app
    cover: cover
    allowedOrientations: Orientation.All

    CommandEngine {
        id: engine
        objectName: 'cengine'
    }

    Page {
        id: loading



    CoverPage {
        id: cover

    }

    Notifications {

    }

    Component.onCompleted: {
        pageStack.clear()
        pageStack.push(Qt.resolvedUrl('pages/sq-gui.qml'), {
            engine: engine,
        })
    }
    }
}
