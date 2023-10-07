#include <QtQuick>
#include <sailfishapp.h>
#include "commandengine.h"


QObject* recursiveFind(QObject* item, QString name)
{
  if (item->objectName() == name)
  {
    return item;
  }
  QObject* result = nullptr;
  QObjectList list = item->children();
  int length = list.count();
  for (int i = 0; i < length; i++)
  {
    QObject* element = list[i];
    result = recursiveFind(element, name);
    if (result != nullptr)
    {
        return result;
    }
  }
  return result;
}

int main(int argc, char *argv[])
{
    QGuiApplication* app = SailfishApp::application(argc, argv);

    CommandEngine* engine = new CommandEngine();

    QQuickView* view = SailfishApp::createView();
    view->rootContext()->setContextProperty("cengine", engine);
    view->setSource(SailfishApp::pathTo("qml/sq-gui.qml"));

    QObject* emitter = recursiveFind(view->rootObject(), "cengine");

    QObject::connect(emitter, SIGNAL(exec(QString, bool)), engine, SLOT(exec(QString, bool)));

    view->show();
    return app->exec();
}

