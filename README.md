# Dynamic Beat Tracking: A Multiple-Agent Approach for Tempo Variation

This is a MATLAB implementation of a beat tracking algorithm that uses complex-domain onset detection[^1] and a multiple-agent beat model[^2]. Detailed information about the implementation, background, and appropriate citations may be found <a href="https://drive.google.com/file/d/1yR6SkaxDkEOfPfXmfeYw10AJ6-bOod9W/view?usp=sharing">here</a>.

## Using the Program

The end-to-end model can be used by created a `BeatTracker` object, which takes in the following parameters for the model:
- `window`: The size of the scoring/correction window in ms
- `mult`: The correction multiplier
- `decay`: The correction decay (must be $<1$)
- `delta`: The tolerance for how similar hypotheses can be before merging (see `Hypothesis.m` for details)

To track the beat of a signal, call `beats(x,fs)` on a `BeatTracker` object, where `x` is the input signal and `fs` is the sampling frequency. For example,
```matlab
tracker = BeatTracker(400,4,0.0001,0.5);
[x,fs] = audioread('sample.wav');
output = tracker.beats(x,fs);
```

Aside from the aforementioned parameters, the onset detection algorithm uses presets for the following values:
- `WIND_N = 128`: STFT window length
- `OVERLAP = 64`: STFT overlap length
- `MED_SHIFT = 0.05`: Median filter vertical shift
- `MED_SCALE = 1`: Median filter scaling factor
These can be manually tuned in the class definition.

## Classes

| Class Name | Function |
|-|-|
| `BeatTracker` | The central class that combines onset detection and beat modelling. |
| `OnsetDetector` | Takes in signal (`[x, fs]`) and finds onsets. An `OnsetDetector` object also stores the found detection function. |
| `BeatModel` | Models the underlying beat based on onset times and other other parameters. |
| `Hypothesis` | Stores a period, phase, and information about scores and corrections over time. |
| `Correction` | Evaluates a hypothesis over a given period and calculates the appropriate correction. |
| `Match` | Stores a pair of values (closest projection and onset times), and their difference. |
| `Util` | Additional methods, including `closestPairs()`. |

[^1]: Bello, J. P., Duxbury, C., Davies, M., & Sandler, M. (2004). On the use of phase and energy for musical onset detection in the complex domain. _IEEE Signal Processing Letters_, _11_(6), 553-556.
[^2]: Miguel, M. A., Sigman, M., & Fernandez Slezak, D. (2020). From beat tracking to beat expectation: Cognitive-based beat tracking for capturing pulse clarity through time. _PloS one_, _15_(11), e0242207.
