/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtQml module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QQMLDATA_P_H
#define QQMLDATA_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <private/qtqmlglobal_p.h>
#include <private/qobject_p.h>
#include <private/qqmlpropertyindex_p.h>
#include <private/qv4value_p.h>
#include <private/qv4persistent_p.h>
#include <qjsengine.h>

QT_BEGIN_NAMESPACE

template <class Key, class T> class QHash;
class QQmlEngine;
class QQmlGuardImpl;
class QQmlAbstractBinding;
class QQmlBoundSignal;
class QQmlContext;
class QQmlPropertyCache;
class QQmlContextData;
class QQmlNotifier;
class QQmlDataExtended;
class QQmlNotifierEndpoint;

namespace QV4 {
namespace CompiledData {
struct CompilationUnit;
}
}

// This class is structured in such a way, that simply zero'ing it is the
// default state for elemental object allocations.  This is crucial in the
// workings of the QQmlInstruction::CreateSimpleObject instruction.
// Don't change anything here without first considering that case!
class Q_QML_PRIVATE_EXPORT QQmlData : public QAbstractDeclarativeData
{
public:
    QQmlData();

    static inline void init() {
        static bool initialized = false;
        if (!initialized) {
            initialized = true;
            QAbstractDeclarativeData::destroyed = destroyed;
            QAbstractDeclarativeData::parentChanged = parentChanged;
            QAbstractDeclarativeData::signalEmitted = signalEmitted;
            QAbstractDeclarativeData::receivers = receivers;
            QAbstractDeclarativeData::isSignalConnected = isSignalConnected;
        }
    }

    static void destroyed(QAbstractDeclarativeData *, QObject *);
    static void parentChanged(QAbstractDeclarativeData *, QObject *, QObject *);
    static void signalEmitted(QAbstractDeclarativeData *, QObject *, int, void **);
    static int receivers(QAbstractDeclarativeData *, const QObject *, int);
    static bool isSignalConnected(QAbstractDeclarativeData *, const QObject *, int);

    void destroyed(QObject *);
    void parentChanged(QObject *, QObject *);

    void setImplicitDestructible() {
        if (!explicitIndestructibleSet) indestructible = false;
    }

    quint32 ownedByQml1:1; // This bit is shared with QML1's QDeclarativeData.
    quint32 ownMemory:1;
    quint32 ownContext:1;
    quint32 indestructible:1;
    quint32 explicitIndestructibleSet:1;
    quint32 hasTaintedV4Object:1;
    quint32 isQueuedForDeletion:1;
    /*
     * rootObjectInCreation should be true only when creating top level CPP and QML objects,
     * v8 GC will check this flag, only deletes the objects when rootObjectInCreation is false.
     */
    quint32 rootObjectInCreation:1;
    quint32 hasInterceptorMetaObject:1;
    quint32 hasVMEMetaObject:1;
    quint32 parentFrozen:1;
    quint32 dummy:21;

    // When bindingBitsSize < 32, we store the binding bit flags inside
    // bindingBitsValue. When we need more than 32 bits, we allocated
    // sufficient space and use bindingBits to point to it.
    int bindingBitsSize;
    union {
        quint32 *bindingBits;
        quint32 bindingBitsValue;
    };

    struct NotifyList {
        quint64 connectionMask;

        quint16 maximumTodoIndex;
        quint16 notifiesSize;

        QQmlNotifierEndpoint *todo;
        QQmlNotifierEndpoint**notifies;
        void layout();
    private:
        void layout(QQmlNotifierEndpoint*);
    };
    NotifyList *notifyList;

    inline QQmlNotifierEndpoint *notify(int index);
    void addNotify(int index, QQmlNotifierEndpoint *);
    int endpointCount(int index);
    bool signalHasEndpoint(int index) const;
    void disconnectNotifiers();

    // The context that created the C++ object
    QQmlContextData *context;
    // The outermost context in which this object lives
    QQmlContextData *outerContext;

    QQmlAbstractBinding *bindings;
    QQmlBoundSignal *signalHandlers;

    // Linked list for QQmlContext::contextObjects
    QQmlData *nextContextObject;
    QQmlData**prevContextObject;

    inline bool hasBindingBit(int) const;
    void clearBindingBit(int);
    void setBindingBit(QObject *obj, int);

    inline bool hasPendingBindingBit(int index) const;
    void setPendingBindingBit(QObject *obj, int);
    void clearPendingBindingBit(int);

    quint16 lineNumber;
    quint16 columnNumber;

    quint32 jsEngineId; // id of the engine that created the jsWrapper

    struct DeferredData {
        unsigned int deferredIdx;
        QV4::CompiledData::CompilationUnit *compilationUnit;//Not always the same as the other compilation unit
        QQmlContextData *context;//Could be either context or outerContext
    };
    QV4::CompiledData::CompilationUnit *compilationUnit;
    DeferredData *deferredData;

    QV4::WeakValue jsWrapper;

    QQmlPropertyCache *propertyCache;

    QQmlGuardImpl *guards;

    static QQmlData *get(const QObject *object, bool create = false) {
        QObjectPrivate *priv = QObjectPrivate::get(const_cast<QObject *>(object));
        if (priv->wasDeleted) {
            Q_ASSERT(!create);
            return 0;
        } else if (priv->declarativeData) {
            return static_cast<QQmlData *>(priv->declarativeData);
        } else if (create) {
            priv->declarativeData = new QQmlData;
            return static_cast<QQmlData *>(priv->declarativeData);
        } else {
            return 0;
        }
    }

    static bool keepAliveDuringGarbageCollection(const QObject *object) {
        QQmlData *ddata = get(object);
        if (!ddata || ddata->indestructible || ddata->rootObjectInCreation)
            return true;
        return false;
    }

    bool hasExtendedData() const { return extendedData != 0; }
    QHash<int, QObject *> *attachedProperties() const;

    static inline bool wasDeleted(QObject *);

    static void markAsDeleted(QObject *);
    static void setQueuedForDeletion(QObject *);

    static inline void flushPendingBinding(QObject *, QQmlPropertyIndex propertyIndex);

    static QQmlPropertyCache *ensurePropertyCache(QJSEngine *engine, QObject *object);

private:
    // For attachedProperties
    mutable QQmlDataExtended *extendedData;

    void flushPendingBindingImpl(QQmlPropertyIndex index);
};

bool QQmlData::wasDeleted(QObject *object)
{
    if (!object)
        return true;

    QObjectPrivate *priv = QObjectPrivate::get(object);
    if (!priv || priv->wasDeleted)
        return true;

    return priv->declarativeData &&
           static_cast<QQmlData *>(priv->declarativeData)->isQueuedForDeletion;
}

QQmlNotifierEndpoint *QQmlData::notify(int index)
{
    Q_ASSERT(index <= 0xFFFF);

    if (!notifyList || !(notifyList->connectionMask & (1ULL << quint64(index % 64)))) {
        return 0;
    } else if (index < notifyList->notifiesSize) {
        return notifyList->notifies[index];
    } else if (index <= notifyList->maximumTodoIndex) {
        notifyList->layout();
    }

    if (index < notifyList->notifiesSize) {
        return notifyList->notifies[index];
    } else {
        return 0;
    }
}

/*
    The index MUST be in the range returned by QObjectPrivate::signalIndex()
    This is different than the index returned by QMetaMethod::methodIndex()
*/
inline bool QQmlData::signalHasEndpoint(int index) const
{
    return notifyList && (notifyList->connectionMask & (1ULL << quint64(index % 64)));
}

bool QQmlData::hasBindingBit(int coreIndex) const
{
    int bit = coreIndex * 2;

    return bindingBitsSize > bit &&
           ((bindingBitsSize == 32) ? (bindingBitsValue & (1 << bit)) :
                                      (bindingBits[bit / 32] & (1 << (bit % 32))));
}

bool QQmlData::hasPendingBindingBit(int index) const
{
    int bit = index * 2 + 1;

    return bindingBitsSize > bit &&
           ((bindingBitsSize == 32) ? (bindingBitsValue & (1 << bit)) :
                                      (bindingBits[bit / 32] & (1 << (bit % 32))));
}

void QQmlData::flushPendingBinding(QObject *o, QQmlPropertyIndex propertyIndex)
{
    QQmlData *data = QQmlData::get(o, false);
    if (data && data->hasPendingBindingBit(propertyIndex.coreIndex()))
        data->flushPendingBindingImpl(propertyIndex);
}

QT_END_NAMESPACE

#endif // QQMLDATA_P_H
