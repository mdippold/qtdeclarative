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

#include <private/qv4iterator_p.h>
#include <private/qv4arrayiterator_p.h>
#include <private/qv4typedarray_p.h>
#include <private/qv4symbol_p.h>

using namespace QV4;

DEFINE_OBJECT_VTABLE(ArrayIteratorObject);

void ArrayIteratorPrototype::init(ExecutionEngine *e)
{
    defineDefaultProperty(QStringLiteral("next"), method_next, 0);

    Scope scope(e);
    ScopedString val(scope, e->newString(QLatin1String("Array Iterator")));
    defineReadonlyConfigurableProperty(e->symbol_toStringTag(), val);
}

ReturnedValue ArrayIteratorPrototype::method_next(const FunctionObject *b, const Value *that, const Value *, int)
{
    Scope scope(b);
    const ArrayIteratorObject *thisObject = that->as<ArrayIteratorObject>();
    if (!thisObject)
        return scope.engine->throwTypeError(QLatin1String("Not an Array Iterator instance"));

    ScopedObject a(scope, thisObject->d()->iteratedObject);
    if (!a) {
        QV4::Value undefined = Primitive::undefinedValue();
        return IteratorPrototype::createIterResultObject(scope.engine, undefined, ScopedValue(scope, Primitive::fromBoolean(true)))->asReturnedValue();
    }

    quint32 index = thisObject->d()->nextIndex;
    ArrayIteratorKind itemKind = thisObject->d()->iterationKind;

    Scoped<TypedArray> ta(scope, a->as<TypedArray>());
    quint32 len = a->getLength();

    if (index >= len) {
        thisObject->d()->iteratedObject.set(scope.engine, nullptr);
        QV4::Value undefined = Primitive::undefinedValue();
        return IteratorPrototype::createIterResultObject(scope.engine, undefined, ScopedValue(scope, Primitive::fromBoolean(true)))->asReturnedValue();
    }

    thisObject->d()->nextIndex = index + 1;
    if (itemKind == KeyIteratorKind) {
        return IteratorPrototype::createIterResultObject(scope.engine, Primitive::fromInt32(index), ScopedValue(scope, Primitive::fromBoolean(false)))->asReturnedValue();
    }

    ReturnedValue elementValue = a->getIndexed(index);
    CHECK_EXCEPTION();

    if (itemKind == ValueIteratorKind) {
        return IteratorPrototype::createIterResultObject(scope.engine, Value::fromReturnedValue(elementValue), ScopedValue(scope, Primitive::fromBoolean(false)))->asReturnedValue();
    } else {
        Q_ASSERT(itemKind == KeyValueIteratorKind);

        ScopedArrayObject resultArray(scope, scope.engine->newArrayObject());
        resultArray->arrayReserve(2);
        resultArray->arrayPut(0, Primitive::fromInt32(index));
        resultArray->arrayPut(1, Value::fromReturnedValue(elementValue));
        resultArray->setArrayLengthUnchecked(2);

        return IteratorPrototype::createIterResultObject(scope.engine, resultArray, ScopedValue(scope, Primitive::fromBoolean(false)))->asReturnedValue();
    }
}

