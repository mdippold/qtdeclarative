/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the QtDeclarative module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** GNU Lesser General Public License Usage
** This file may be used under the terms of the GNU Lesser General Public
** License version 2.1 as published by the Free Software Foundation and
** appearing in the file LICENSE.LGPL included in the packaging of this
** file. Please review the following information to ensure the GNU Lesser
** General Public License version 2.1 requirements will be met:
** http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain additional
** rights. These rights are described in the Nokia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU General
** Public License version 3.0 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of this
** file. Please review the following information to ensure the GNU General
** Public License version 3.0 requirements will be met:
** http://www.gnu.org/copyleft/gpl.html.
**
** Other Usage
** Alternatively, this file may be used in accordance with the terms and
** conditions contained in a signed written agreement between you and Nokia.
**
**
**
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QDECLARATIVEOBSERVERSERVICE_H
#define QDECLARATIVEOBSERVERSERVICE_H

#include "private/qdeclarativedebugservice_p.h"
#include <private/qdeclarativeglobal_p.h>

#include <QtCore/QList>

QT_BEGIN_HEADER

QT_BEGIN_NAMESPACE

QT_MODULE(Declarative)

class QDeclarativeView;
class QDeclarativeObserverInterface;

class Q_DECLARATIVE_EXPORT QDeclarativeObserverService : public QDeclarativeDebugService
{
    Q_OBJECT

public:
    QDeclarativeObserverService();
    static QDeclarativeObserverService *instance();

    void addView(QDeclarativeView *);
    void removeView(QDeclarativeView *);
    QList<QDeclarativeView*> views() const { return m_views; }

    void sendMessage(const QByteArray &message);

Q_SIGNALS:
    void gotMessage(const QByteArray &message);

protected:
    virtual void statusChanged(Status status);
    virtual void messageReceived(const QByteArray &);

private:
    static QDeclarativeObserverInterface *loadObserverPlugin();

    QList<QDeclarativeView*> m_views;
    QDeclarativeObserverInterface *m_observer;
};

QT_END_NAMESPACE

QT_END_HEADER

#endif // QDECLARATIVEOBSERVERSERVICE_H
