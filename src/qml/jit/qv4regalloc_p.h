/****************************************************************************
**
** Copyright (C) 2012 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the V4VM module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.  For licensing terms and
** conditions see http://qt.digia.com/licensing.  For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights.  These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/
#ifndef QV4REGALLOC_P_H
#define QV4REGALLOC_P_H

#include "qv4global_p.h"
#include "qv4isel_p.h"
#include "qv4ssa_p.h"

#include <config.h>

QT_BEGIN_NAMESPACE

namespace QV4 {
namespace JIT {

class RegAllocInfo;

class RegisterAllocator
{
    typedef IR::LifeTimeInterval LifeTimeInterval;

    QVector<int> _normalRegisters;
    QVector<int> _fpRegisters;
    QScopedPointer<RegAllocInfo> _info;

    QVector<LifeTimeInterval *> _fixedRegisterRanges, _fixedFPRegisterRanges;

    IR::LifeTimeIntervals::Ptr _lifeTimeIntervals;
    typedef QVector<LifeTimeInterval *> Intervals;
    Intervals _unhandled, _active, _inactive, _handled;

    std::vector<int> _lastAssignedRegister;
    std::vector<int> _assignedSpillSlots;
    QVector<int> _activeSpillSlots;

    Q_DISABLE_COPY(RegisterAllocator)

public:
    enum { Invalid = -1 };

    RegisterAllocator(const QVector<int> &normalRegisters, const QVector<int> &fpRegisters);
    ~RegisterAllocator();

    void run(IR::Function *function, const IR::Optimizer &opt);

private:
    LifeTimeInterval *cloneFixedInterval(int reg, bool isFP, const LifeTimeInterval &original);
    void prepareRanges();
    void linearScan();
    void tryAllocateFreeReg(LifeTimeInterval &current, const int position);
    void allocateBlockedReg(LifeTimeInterval &current, const int position);
    int nextIntersection(const LifeTimeInterval &current, const LifeTimeInterval &another,
                         const int position) const;
    int nextUse(const IR::Temp &t, int startPosition) const;
    void split(LifeTimeInterval &current, int beforePosition, bool skipOptionalRegisterUses =false);
    void splitInactiveAtEndOfLifetimeHole(int reg, bool isFPReg, int position);
    void assignSpillSlot(const IR::Temp &t, int startPos, int endPos);
    void resolve(IR::Function *function, const IR::Optimizer &opt);

    void dump() const;
};

} // end of namespace JIT
} // end of namespace QV4

QT_END_NAMESPACE

#endif // QV4REGALLOC_P_H
