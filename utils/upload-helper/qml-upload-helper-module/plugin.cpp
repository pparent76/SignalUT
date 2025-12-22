#include <qqml.h>
#include <QQmlExtensionPlugin>
#include "UploadHelper.h"

class UploadHelperPlugin :  public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
void registerTypes(const char *uri) override
{
    // uri doit correspondre à celui du qmldir
    Q_ASSERT(uri == QStringLiteral("Pparent.UploadHelper"));
    qmlRegisterType<UploadHelper>(uri, 1, 0, "UploadHelper");
}
};  
#include "plugin.moc"
