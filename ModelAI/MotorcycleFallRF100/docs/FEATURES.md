# The 24 features

For N=200 decimated samples per window, use acceleration vector a_i, gyro vector
g_i, acceleration magnitude A_i=norm(a_i) and gyro magnitude G_i=norm(g_i).
All means use 1/N. Window standard deviations are population STD (ddof=0).
These are fixed engineered features; RF learns splits between them. Their
usefulness is an empirical hypothesis, not a claim that this set is optimal.

| Index | Name | Definition / unit | Purpose |
|---|---|---|---|
| 0 | A_max | max A_i; m/s^2 | Strong acceleration excursion |
| 1 | A_mean | mean A_i; m/s^2 | Typical magnitude, including gravity |
| 2 | A_std | sqrt(mean((A_i-mean A)^2)); m/s^2 | Magnitude variation |
| 3 | A_rms | sqrt(mean(A_i^2)); m/s^2 | Overall amplitude |
| 4 | G_max | max G_i; deg/s | Strongest rotation |
| 5 | G_mean | mean G_i; deg/s | Typical rotational activity |
| 6 | G_std | population STD of G_i; deg/s | Rotation variation |
| 7 | jerk_max | max norm((a_i-a_(i-1))*100); m/s^3 | Abrupt force change |
| 8 | tilt_proxy_end_deg | last atan2(sqrt(Ax^2+Ay^2), abs(Az)+1e-12); degrees | Acceleration-direction proxy |
| 9 | tilt_proxy_max_deg | maximum same proxy; degrees | Largest proxy excursion |
| 10 | tilt_proxy_change_deg | last minus first proxy; degrees | Direction change inside window |
| 11 | Az_second_half_mean | mean Az over last 100 samples; m/s^2 | Recent vertical-channel level |
| 12 | still_A | fraction abs(A_i-9.81)<1.5 | Gravity-magnitude proximity |
| 13 | still_G | fraction G_i<5 deg/s | Low rotation fraction |
| 14 | freefall_fraction | fraction A_i<0.5*9.81 | Low specific-force fraction |
| 15 | Ax_absmax | max abs(Ax); m/s^2 | Axis excursion |
| 16 | Ay_absmax | max abs(Ay); m/s^2 | Axis excursion |
| 17 | Az_absmax | max abs(Az); m/s^2 | Axis excursion |
| 18 | Gx_absmax | max abs(Gx); deg/s | Axis rotation excursion |
| 19 | Gy_absmax | max abs(Gy); deg/s | Axis rotation excursion |
| 20 | Gz_absmax | max abs(Gz); deg/s | Axis rotation excursion |
| 21 | fft_energy_0_5 | power summed over 0<=f<5 Hz | Slow magnitude changes |
| 22 | fft_energy_5_15 | power summed over 5<=f<15 Hz | Intermediate-band variation |
| 23 | fft_energy_15_40 | power summed over 15<=f<40 Hz | Faster magnitude variation |

FFT is computed on the demeaned acceleration MAGNITUDE, not on six raw channels.
For X_k = rFFT(A_i - mean(A)), power P_k = c_k abs(X_k)^2/N^2, where c=2 except
DC and the even-length Nyquist bin, where c=1. Sum P_k over the stated bands.
Energy units are (m/s^2)^2; the full one-sided sum equals the demeaned signal's
mean-square value by Parseval. There is no taper window in this implementation.

The 25 Hz prefilter attenuates the top part of the 15-40 Hz band; the band is a
declared baseline feature retained from the previous RF design, not evidence
that frequencies above the cutoff are unattenuated. Bands, thresholds and
feature definitions are identical across the measured-only and mixed models.

The tilt proxy is bounded near 0..90 degrees because abs(Az) is used. It cannot
identify inversion and is affected by translational acceleration. It must not
be presented as an independently estimated physical roll/pitch angle.

This implementation uses the previous model's 24 feature NAMES with the explicit
definitions above. The old Python source ZIP was truncated, so bit-for-bit
identity with every historical feature formula is not claimed. New models are
trained and predicted using this one shared implementation.
