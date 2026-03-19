#include <QGuiApplication>
#include <QDesktopServices>
#include <QUrl>
#include <QString>
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qWarning() << "Calling dummy Qt app to kill the placeholder";
    return 1;
  
}
