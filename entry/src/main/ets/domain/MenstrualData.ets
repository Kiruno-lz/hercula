import { addDays, dayDistance, isValidDateKey, parseDateKey } from './DateUtils';

export interface MenstrualDay {
  date: string;
  source: 'manual' | 'import';
}

export interface PeriodSummary {
  startDate: string;
  endDate: string;
  durationDays: number;
  ongoing: boolean;
}

export interface Prediction {
  label: string;
  available: boolean;
}

export type OvulationPredictionMethod = 'calendar' | 'skinTemperature';

export interface SkinTemperatureSample {
  date: string;
  temperatureCelsius: number;
}

export interface OvulationPredictionInput {
  nextPeriodStartDate: string;
  skinTemperatureSamples: Array<SkinTemperatureSample>;
}

export interface OvulationPrediction {
  method: OvulationPredictionMethod;
  date: string;
  windowStart: string;
  windowEnd: string;
  lutealPhaseDays: number;
}

export interface OvulationPredictionStrategy {
  predict(input: OvulationPredictionInput): OvulationPrediction;
}

export interface CycleForecast {
  nextPeriodStartDate: string;
  estimatedCycleLengthDays: number;
  probabilityBandwidthDays: number;
  ovulation: OvulationPrediction;
  periodProbability: Array<PeriodProbability>;
  highProbabilityDates: Array<string>;
}

export interface PeriodProbability {
  date: string;
  probability: number;
}

const MAX_RECENT_CYCLE_LENGTHS: number = 12;
const DEFAULT_LUTEAL_PHASE_DAYS: number = 14;
const MIN_LUTEAL_PHASE_DAYS: number = 11;
const MAX_LUTEAL_PHASE_DAYS: number = 17;
const PERIOD_PROBABILITY_BANDWIDTH_DAYS: number = 2;
const DEFAULT_HIGH_PROBABILITY_THRESHOLD: number = 0.6;

class CalendarOvulationPredictionStrategy implements OvulationPredictionStrategy {
  predict(input: OvulationPredictionInput): OvulationPrediction {
    return {
      method: 'calendar',
      date: addDays(input.nextPeriodStartDate, -DEFAULT_LUTEAL_PHASE_DAYS),
      windowStart: addDays(input.nextPeriodStartDate, -MAX_LUTEAL_PHASE_DAYS),
      windowEnd: addDays(input.nextPeriodStartDate, -MIN_LUTEAL_PHASE_DAYS),
      lutealPhaseDays: DEFAULT_LUTEAL_PHASE_DAYS
    };
  }
}

const CALENDAR_OVULATION_STRATEGY: OvulationPredictionStrategy =
  new CalendarOvulationPredictionStrategy();

export function normalizeDays(days: Array<MenstrualDay>): Array<MenstrualDay> {
  const byDate: Map<string, MenstrualDay> = new Map<string, MenstrualDay>();
  days.forEach((item: MenstrualDay) => {
    if (isValidDateKey(item.date)) {
      byDate.set(item.date, item);
    }
  });
  const dates: Array<string> = Array.from(byDate.keys()).sort();
  return dates.map((date: string): MenstrualDay => {
    return byDate.get(date) as MenstrualDay;
  });
}

export function derivePeriods(days: Array<MenstrualDay>, today: string): Array<PeriodSummary> {
  const normalizedDates: Array<string> = normalizeDays(days)
    .map((item: MenstrualDay): string => item.date)
    .filter((date: string): boolean => date <= today);
  const result: Array<PeriodSummary> = [];
  normalizedDates.forEach((startDate: string, index: number) => {
    const nextDate: string | undefined = normalizedDates[index + 1];
    const ongoing: boolean = nextDate === undefined;
    const endDate: string = ongoing ? today : addDays(nextDate, -1);
    const durationDays: number = ongoing
      ? dayDistance(startDate, today)
      : dayDistance(startDate, nextDate);
    result.push({
      startDate: startDate,
      endDate: endDate,
      durationDays: Math.max(1, durationDays),
      ongoing: ongoing
    });
  });
  return result;
}

export function predictCycleForecast(
  periods: Array<PeriodSummary>,
  highProbabilityThreshold: number = DEFAULT_HIGH_PROBABILITY_THRESHOLD
): CycleForecast | undefined {
  const startDates: Array<string> = periods
    .map((period: PeriodSummary): string => period.startDate)
    .sort();
  if (startDates.length === 0) {
    return undefined;
  }

  const cycleLengths: Array<number> = [];
  for (let index: number = 1; index < startDates.length; index += 1) {
    cycleLengths.push(dayDistance(startDates[index - 1], startDates[index]));
  }
  if (cycleLengths.length === 0) {
    cycleLengths.push(28);
  }

  const recentCycleLengths: Array<number> = cycleLengths.slice(-MAX_RECENT_CYCLE_LENGTHS);
  const estimatedCycleLengthDays: number = Math.round(timeWeightedAverage(recentCycleLengths));
  const probabilityBandwidthDays: number = calculateProbabilityBandwidth(recentCycleLengths);
  const periodProbability: Array<PeriodProbability> = buildPeriodProbability(
    startDates[startDates.length - 1],
    recentCycleLengths,
    probabilityBandwidthDays
  );
  const peakProbability: number = periodProbability.reduce(
    (maximum: number, item: PeriodProbability): number => Math.max(maximum, item.probability),
    0
  );
  const threshold: number = Math.max(0, Math.min(1, highProbabilityThreshold));
  const highProbabilityDates: Array<string> = periodProbability
    .filter((item: PeriodProbability): boolean => {
      return item.probability >= peakProbability * threshold;
    })
    .map((item: PeriodProbability): string => item.date);
  const nextPeriodStartDate: string = addDays(
    startDates[startDates.length - 1],
    estimatedCycleLengthDays
  );
  return {
    nextPeriodStartDate: nextPeriodStartDate,
    estimatedCycleLengthDays: estimatedCycleLengthDays,
    probabilityBandwidthDays: probabilityBandwidthDays,
    ovulation: CALENDAR_OVULATION_STRATEGY.predict({
      nextPeriodStartDate: nextPeriodStartDate,
      skinTemperatureSamples: []
    }),
    periodProbability: periodProbability,
    highProbabilityDates: highProbabilityDates
  };
}

export function predictNextPeriod(periods: Array<PeriodSummary>): Prediction {
  const startDates: Array<string> = periods
    .map((period: PeriodSummary): string => period.startDate)
    .sort();
  if (startDates.length < 3) {
    return { available: false, label: '记录更多完整周期后显示估算' };
  }
  const forecast: CycleForecast | undefined = predictCycleForecast(periods);
  if (forecast === undefined) {
    return { available: false, label: '记录更多完整周期后显示估算' };
  }
  return {
    available: true,
    label: formatForecastRange(forecast.highProbabilityDates, forecast.nextPeriodStartDate)
  };
}

function buildPeriodProbability(
  latestStartDate: string,
  cycleLengths: Array<number>,
  bandwidthDays: number
): Array<PeriodProbability> {
  let minimumCycleLength: number = cycleLengths[0];
  let maximumCycleLength: number = cycleLengths[0];
  cycleLengths.forEach((cycleLength: number): void => {
    minimumCycleLength = Math.min(minimumCycleLength, cycleLength);
    maximumCycleLength = Math.max(maximumCycleLength, cycleLength);
  });
  minimumCycleLength = Math.max(1, minimumCycleLength);
  const paddingDays: number = Math.ceil(bandwidthDays * 2);
  const firstCandidate: number = Math.max(
    1,
    minimumCycleLength - paddingDays
  );
  const lastCandidate: number = maximumCycleLength + paddingDays;
  const weightedValues: Array<number> = [];
  let totalProbability: number = 0;

  for (let candidate: number = firstCandidate; candidate <= lastCandidate; candidate += 1) {
    let weightedProbability: number = 0;
    cycleLengths.forEach((cycleLength: number, index: number): void => {
      const recencyWeight: number = index + 1;
      const distance: number = candidate - cycleLength;
      const kernelWeight: number = Math.exp(
        -(distance * distance) / (2 * bandwidthDays * bandwidthDays)
      );
      weightedProbability += recencyWeight * kernelWeight;
    });
    weightedValues.push(weightedProbability);
    totalProbability += weightedProbability;
  }

  const result: Array<PeriodProbability> = [];
  for (let index: number = 0; index < weightedValues.length; index += 1) {
    result.push({
      date: addDays(latestStartDate, firstCandidate + index),
      probability: totalProbability === 0 ? 0 : weightedValues[index] / totalProbability
    });
  }
  return result;
}

function calculateProbabilityBandwidth(values: Array<number>): number {
  const weightedMean: number = timeWeightedAverage(values);
  let weightedVariance: number = 0;
  let totalWeight: number = 0;
  let squaredWeightTotal: number = 0;
  values.forEach((value: number, index: number): void => {
    const weight: number = index + 1;
    const difference: number = value - weightedMean;
    weightedVariance += weight * difference * difference;
    totalWeight += weight;
    squaredWeightTotal += weight * weight;
  });
  const effectiveSampleSize: number = totalWeight === 0
    ? 1
    : (totalWeight * totalWeight) / squaredWeightTotal;
  const stabilizedDeviation: number = Math.sqrt(
    (weightedVariance / Math.max(1, totalWeight) +
      PERIOD_PROBABILITY_BANDWIDTH_DAYS * PERIOD_PROBABILITY_BANDWIDTH_DAYS) / 2
  );
  const silvermanBandwidth: number = 1.06 * stabilizedDeviation * Math.pow(effectiveSampleSize, -0.2);
  return Math.max(1.5, Math.min(4.5, silvermanBandwidth));
}

function formatForecastRange(dates: Array<string>, fallbackDate: string): string {
  const startDate: Date = parseDateKey(dates.length === 0 ? fallbackDate : dates[0]);
  const endDate: Date = parseDateKey(dates.length === 0 ? fallbackDate : dates[dates.length - 1]);
  if (startDate.getTime() === endDate.getTime()) {
    return `${startDate.getFullYear()}年${startDate.getMonth() + 1}月${startDate.getDate()}日左右`;
  }
  if (startDate.getFullYear() === endDate.getFullYear()
    && startDate.getMonth() === endDate.getMonth()) {
    return `${startDate.getFullYear()}年${startDate.getMonth() + 1}月${startDate.getDate()}-${endDate.getDate()}日左右`;
  }
  return `${startDate.getFullYear()}年${startDate.getMonth() + 1}月${startDate.getDate()}日-` +
    `${endDate.getFullYear()}年${endDate.getMonth() + 1}月${endDate.getDate()}日左右`;
}

function timeWeightedAverage(values: Array<number>): number {
  let weightedTotal: number = 0;
  let totalWeight: number = 0;
  values.forEach((value: number, index: number): void => {
    const weight: number = index + 1;
    weightedTotal += value * weight;
    totalWeight += weight;
  });
  if (totalWeight === 0) {
    return 0;
  }
  return weightedTotal / totalWeight;
}
