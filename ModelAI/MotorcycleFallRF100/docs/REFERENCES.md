# Sources and implementation references

1. Boubezoul et al., Dataset on powered two wheelers fall and critical events
   detection, Data in Brief (2019): https://doi.org/10.1016/j.dib.2019.103828
   Dataset/contact annotations, not a learned RF100 model source.
2. Corrigendum to the above dataset (2020):
   https://doi.org/10.1016/j.dib.2020.105577
   The current raw bytes have not been verified against the corrected supplement.
3. Breiman, Random Forests, Machine Learning 45 (2001), 5-32:
   https://doi.org/10.1023/A:1010933404324
4. scikit-learn RandomForestClassifier:
   https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html
5. SciPy causal SOS filtering:
   https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.sosfilt.html
6. SciPy Butterworth filter design:
   https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html
7. NumPy real FFT:
   https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html
8. Ahmed et al., Data Analysis on Powered Two Wheelers Riders' Behaviour Using
   Machine Learning, ASPAI 2019, pp.159-163:
   https://www.es.mdu.se/publications/5392-Data_Analysis_on_Powered_Two_Wheelers_Riders____Behaviour_using_Machine_Learning
   Related feature-based IMU workflow. That study classifies riding patterns;
   its four-class results are not this project's fall-detection performance.

The 100-tree budget, depth limit, feature set, class/parent balancing, timing
guard and alarm rules are declared project design choices. They are not claimed
as experimentally optimal or specified by the ASPAI paper.
