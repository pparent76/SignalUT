#pragma once

#include <QObject>
#include <QString>
#include <QProcess>

class DownloadHelper : public QObject
{

    Q_PROPERTY(QString blob_path READ get_blob_path WRITE set_blob_path)
    Q_OBJECT
public:
    explicit DownloadHelper(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE QString getLastDownloaded();

    QString get_blob_path();
    void set_blob_path(QString value);
private:
    QString blob_path;
};
