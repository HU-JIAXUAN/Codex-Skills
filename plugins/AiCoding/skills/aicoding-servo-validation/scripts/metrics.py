#!/usr/bin/env python3
"""对离线伺服CSV计算误差、电流与有定义的停稳指标；不连接设备。"""
from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
import sys


def time_rms(times: list[float], values: list[float]) -> float:
    """按梯形积分计算时间加权RMS，独立保留样本RMS口径。"""
    area = sum((times[i] - times[i - 1]) * (values[i] ** 2 + values[i - 1] ** 2) / 2
               for i in range(1, len(times)))
    return math.sqrt(area / (times[-1] - times[0]))


def calculate(rows: list[dict[str, float]], *, settle_start: float | None = None,
              band: float = 0.001, hold: float = 0.05) -> dict:
    """计算指标；停稳从最后一次越带之后开始，记录长度须足够。"""
    if len(rows) < 2:
        raise ValueError('至少需要两个样本')
    required = ('time_s', 'reference_rad', 'position_rad')
    has_current = ['current_a' in row for row in rows]
    if any(has_current) and not all(has_current):
        raise ValueError('current_a必须在全部样本中提供或全部省略')
    for row in rows:
        for key in required + (('current_a',) if all(has_current) else ()):
            if key not in row or not math.isfinite(row[key]):
                raise ValueError(f'缺少或非有限数值: {key}')
    times = [row['time_s'] for row in rows]
    if any(b <= a for a, b in zip(times, times[1:])):
        raise ValueError('time_s必须严格递增')
    errors = [row['reference_rad'] - row['position_rad'] for row in rows]
    result = {
        'samples': len(rows), 'duration_s': times[-1] - times[0],
        'error_peak_rad': max(abs(e) for e in errors),
        'error_rms_samples_rad': math.sqrt(sum(e * e for e in errors) / len(errors)),
        'error_rms_time_rad': time_rms(times, errors),
        'settling': None,
    }
    if all(has_current):
        currents = [row['current_a'] for row in rows]
        result.update(current_peak_a=max(abs(i) for i in currents),
                      current_rms_time_a=time_rms(times, currents))
    if settle_start is not None:
        if not all(math.isfinite(x) for x in (settle_start, band, hold)) or band <= 0 or hold <= 0:
            raise ValueError('停稳起点必须有限，误差带/保持时间必须有限且为正')
        if not times[0] <= settle_start <= times[-1]:
            raise ValueError('停稳起点不在记录范围内')
        indices = [i for i, t in enumerate(times) if t >= settle_start]
        refs = [rows[i]['reference_rad'] for i in indices]
        tolerance = 1e-12 * max(1.0, *(abs(v) for v in refs))
        if max(refs) - min(refs) > tolerance:
            raise ValueError('停稳计算段内reference_rad必须恒定；运动跟随应只计算误差指标')
        last_bad = max((i for i in indices if abs(errors[i]) > band), default=indices[0] - 1)
        candidate = next((i for i in indices if i > last_bad), None)
        settled = candidate is not None and times[-1] - times[candidate] >= hold
        result['settling'] = {
            'start_s': settle_start, 'band_rad': band, 'minimum_hold_s': hold,
            'settled': settled,
            'settling_time_s': times[candidate] - settle_start if settled else None,
            'sampling_resolution_max_s': max(b - a for a, b in zip(times, times[1:])),
            'definition': '最后一次越带之后进入，并在余下记录中保持且不少于指定保持时间',
        }
    return result


def self_test() -> dict:
    """用独立常值真值、晚期越带和非法记录验证可观察行为。"""
    count = 0
    rows = [dict(time_s=t, reference_rad=2.0, position_rad=0.0, current_a=3.0) for t in (0.0, 1.0, 3.0)]
    result = calculate(rows)
    assert result['error_peak_rad'] == result['error_rms_time_rad'] == 2.0
    count += 1
    assert result['current_rms_time_a'] == result['current_peak_a'] == 3.0
    count += 1
    rows = [dict(time_s=float(i), reference_rad=1.0, position_rad=p) for i, p in enumerate((0., 0., 1., 1., 1.))]
    assert calculate(rows, settle_start=0.0, band=.1, hold=1.)['settling']['settling_time_s'] == 2.
    count += 1
    rows[-2]['position_rad'] = 0.
    assert not calculate(rows, settle_start=0., band=.1, hold=1.)['settling']['settled']
    count += 1
    bad_records = [
        [],
        [dict(time_s=0., reference_rad=0., position_rad=0.)] * 2,
        [dict(time_s=0., reference_rad=0., position_rad=float('nan')), dict(time_s=1., reference_rad=0., position_rad=0.)],
        [dict(time_s=0., reference_rad=0., position_rad=0., current_a=0.), dict(time_s=1., reference_rad=0., position_rad=0.)],
    ]
    for bad in bad_records:
        try:
            calculate(bad)
        except ValueError:
            count += 1
        else:
            raise AssertionError('非法记录未被拒绝')
    moving = [dict(time_s=0., reference_rad=0., position_rad=0.), dict(time_s=1., reference_rad=1., position_rad=1.)]
    try:
        calculate(moving, settle_start=0.)
    except ValueError:
        count += 1
    else:
        raise AssertionError('运动中的参考被误算停稳')
    return {'passed': count, 'failed': 0}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv', nargs='?', type=Path)
    parser.add_argument('--settle-start', type=float)
    parser.add_argument('--band', type=float, default=.001)
    parser.add_argument('--hold', type=float, default=.05)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    try:
        if args.self_test:
            result = self_test()
        else:
            if args.csv is None:
                parser.error('需要CSV文件或--self-test')
            with args.csv.open(encoding='utf-8-sig', newline='') as stream:
                rows = [{key: float(value) for key, value in row.items() if key is not None and value != ''}
                        for row in csv.DictReader(stream)]
            result = calculate(rows, settle_start=args.settle_start, band=args.band, hold=args.hold)
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 0
    except (ValueError, KeyError, OSError, AssertionError, OverflowError) as exc:
        print(json.dumps({'error': str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
