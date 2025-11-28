#include <qqml.h>
#include <QQmlExtensionPlugin>
#include "DownloadHelper.h"

class DownloadHelperPlugin :  public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
void registerTypes(const char *uri) override
{
    // uri doit correspondre à celui du qmldir
    Q_ASSERT(uri == QStringLiteral("Pparent.DownloadHelper"));
    qmlRegisterType<DownloadHelper>(uri, 1, 0, "DownloadHelper");
}
};  
#include "plugin.moc"
