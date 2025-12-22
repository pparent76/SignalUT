#include "UploadHelper.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QByteArray>
#include <QDebug>
#include <QDirIterator>
#include <QDateTime>


QString findNewestFile(const QString &dirPath) {
    QDir dir(dirPath);
    QFileInfo newestFile;
    qint64 newestTime = 0;

    // Ne liste que les fichiers du dossier courant
    QFileInfoList files = dir.entryInfoList(
        QDir::Files,
        QDir::Time | QDir::Reversed // du plus récent au plus ancien
    );

    for (const QFileInfo &fi : files) {
        qint64 mtime = fi.lastModified().toSecsSinceEpoch();
        if (mtime > newestTime) {
            newestTime = mtime;
            newestFile = fi;
        }
    }

    if (!newestFile.exists()) {
        qWarning() << "No file found in" << dirPath;
        return "";
    }

    return newestFile.absoluteFilePath();
}

void clearCache(const QString &dirPath)
{
    QDirIterator it(dirPath, QDir::Files, QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        QFileInfo fi = it.fileInfo();
        
        // Supprime le fichier
        QFile file(fi.absoluteFilePath());
        if (!file.remove()) {
            qWarning() << "Could not delete" << fi.absoluteFilePath();
        } else {
            qDebug() << "Deleted :" << fi.absoluteFilePath();
        }
    }
}

void UploadHelper::uploadFile(QString path)
{
    clearCache(blob_path);
    QFileInfo fi(path);
    QString destination = blob_path + fi.fileName();
    qDebug() << "Copy "<<path<<" to "<<destination;
    QFile::copy(path, destination);
    QFile::remove(path);
}



QString UploadHelper::get_blob_path() 
{ return blob_path; }
   
void UploadHelper::set_blob_path(QString value)
{ blob_path = value; }
 


