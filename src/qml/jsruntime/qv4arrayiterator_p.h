/****************************************************************************
**
** Copyright (C) 2017 Crimson AS <info@crimson.no>
** Copyright (C) 2018 The Qt Company Ltd.
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

#ifndef QV4ARRAYITERATOR_P_H
#define QV4ARRAYITERATOR_P_H

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

#include "qv4object_p.h"
#include "qv4arraydata_p.h"

QT_BEGIN_NAMESPACE


namespace QV4 {

// ### spec says that this is a string, but I don't see it exposed anywhere, so
// does that matter?
// ### maybe we should share this with other iterator types in the future.
enum ArrayIteratorKind {
    KeyIteratorKind,
    ValueIteratorKind,
    KeyValueIteratorKind
};

namespace Heap {

#define ArrayIteratorObjectMembers(class, Member) \
    Member(class, Pointer, Object *, iteratedObject) \
    Member(class, NoMark, ArrayIteratorKind, iterationKind) \
    Member(class, NoMark, quint32, nextIndex)

DECLARE_HEAP_OBJECT(ArrayIteratorObject, Object) {
    DECLARE_MARKOBJECTS(ArrayIteratorObject);
    void init(Object *obj, QV4::ExecutionEngine *engine)
    {
        Object::init();
        this->iteratedObject.set(engine, obj);
        this->nextIndex = 0;
    }
};

}

struct ArrayIteratorPrototype : Object
{
    V4_PROTOTYPE(iteratorPrototype)
    void init(ExecutionEngine *engine);

    static ReturnedValue method_next(const FunctionObject *b, const Value *thisObject, const Value *argv, int argc);
};

struct ArrayIteratorObject : Object
{
    V4_OBJECT2(ArrayIteratorObject, Object)
    Q_MANAGED_TYPE(ArrayIteratorObject)
    V4_PROTOTYPE(arrayIteratorPrototype)

    void init(ExecutionEngine *engine);
};


}

QT_END_NAMESPACE

#endif // QV4ARRAYITERATOR_P_H

