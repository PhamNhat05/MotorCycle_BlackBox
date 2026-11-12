# Hộp đen thông minh cho xe máy

Đồ án PBL5 xây dựng nguyên mẫu hộp đen thu tín hiệu quán tính của xe máy và đánh giá khả năng nhận diện ngã bằng mô hình Random Forest. Khi xác nhận ngã, thiết bị được thiết kế để gửi SMS kèm tọa độ GPS đến số liên hệ đã cài đặt. Phần nhúng hiện thực hiện lấy mẫu và lưu dữ liệu IMU. Mô hình nhận diện đã được đánh giá trên máy tính. Suy luận trên ESP32-S3, định vị và gửi SMS là các phần cần tích hợp và kiểm thử.

## Cấu trúc kho mã

```text
MotorCycle_BlackBox/
├── README.md
├── Data/                             # Bản ghi IMU thực nghiệm
├── Simulate/
│   └── MotorcycleIMULab/
│       ├── RUN_ALL.m
│       ├── RUN_ORIGINAL.m
│       ├── RUN_AUGMENT.m
│       ├── ORIGINAL/                 # Tái dựng tín hiệu từ bản ghi gốc
│       └── AUGMENTED/                # Sinh biến thể IMU
├── ModelAI/
│   └── MotorcycleFallRF100/
│       ├── train.py
│       ├── predict.py
│       ├── requirements.txt
│       ├── config/
│       ├── rf100/
│       └── results/
│           └── RUN_20261110_121039_061836/
│               ├── best_model.joblib
│               └── models/
│                   ├── mixed__rf100.joblib
│                   └── real_only__rf100.joblib
└── firmware/
    ├── platformio.ini
    └── src/                          # Đọc IMU và ghi microSD
```

| Thư mục | Nội dung |
| --- | --- |
| [`Data/`](Data/) | Các bản ghi IMU thực nghiệm và tệp dữ liệu nguồn. |
| [`Simulate/`](Simulate/MotorcycleIMULab/) | Mã MATLAB tái dựng tín hiệu IMU từ bản ghi đo và sinh biến thể cảm biến. |
| [`ModelAI/`](ModelAI/MotorcycleFallRF100/) | Mã Python tiền xử lý, huấn luyện, đánh giá và dự đoán bằng RF100. Các tệp mô hình đã huấn luyện có định dạng `.joblib`. |
| [`firmware/`](firmware/) | Dự án PlatformIO cho ESP32-S3, thu dữ liệu từ MPU6050 và ghi lên thẻ microSD. |

## Quy trình xử lý

1. **Tái dựng tín hiệu IMU.** Dùng động học vật rắn để tái dựng gia tốc và vận tốc góc trên sáu trục từ 10 bản ghi thực nghiệm. Đối chiếu tín hiệu tái dựng với dữ liệu đo trước khi tạo biến thể.
2. **Tăng cường dữ liệu.** Sinh 100 biến thể cho mỗi bản ghi, tổng cộng 1.000 biến thể, bằng cách thay đổi độ lệch cảm biến, vị trí lắp hoặc kết hợp cả hai. Các biến thể dùng chung chuyển động với bản ghi gốc.
3. **Huấn luyện và đánh giá.** Dùng bộ lọc thông thấp Butterworth bậc 4 ở 25 Hz trước khi hạ tần từ 1.000 Hz xuống 100 Hz. Trích xuất 24 đặc trưng trên mỗi cửa sổ thời gian cho mô hình Random Forest 100 cây, độ sâu tối đa 8. Chia bản ghi gốc theo tỷ lệ 6/2/2 cho huấn luyện, chọn mô hình và kiểm tra. Mỗi biến thể đi cùng nhóm với bản ghi gốc để tránh rò rỉ dữ liệu.
4. **Thu dữ liệu trên thiết bị.** ESP32-S3 đọc gia tốc và vận tốc góc ba trục từ MPU6050 ở tần số danh định 200 Hz. Tác vụ lấy mẫu chuyển dữ liệu qua hàng đợi để tác vụ ghi thẻ lưu các mẫu cùng dấu thời gian lên microSD.

### Tham khảo cấu trúc Random Forest

Nghiên cứu của **Mobyen Uddin Ahmed và cộng sự** là tài liệu tham khảo trực tiếp cho cách tổ chức bộ phân loại của đồ án. Bài báo chia tín hiệu IMU sáu trục thành các cửa sổ, trích xuất đặc trưng miền thời gian và miền tần số, rồi so sánh Random Forest, SVM và ANN trên bài toán phân loại tình huống lái xe hai bánh. Phần Random Forest dùng `RandomForestClassifier` của scikit-learn và khảo sát các tham số như số cây, độ sâu, số mẫu tối thiểu ở nút lá và số đặc trưng được xét khi chia nút. Đồ án áp dụng cách tiếp cận này cho bài toán nhị phân **ngã và không ngã**, với cấu hình riêng gồm **100 cây, độ sâu tối đa 8 và 24 đặc trưng**. [Bài báo của Ahmed và cộng sự tại ASPAI 2019](https://www.es.mdu.se/publications/5392-Data_Analysis_on_Powered_Two_Wheelers_Riders____Behaviour_using_Machine_Learning)

## Kết quả đánh giá

Mô hình được chọn là RF100 huấn luyện với dữ liệu thực và dữ liệu tăng cường, với ngưỡng nhận diện **0,70**. Trên hai bản ghi thực dành riêng cho kiểm tra, mô hình phân loại đúng **333 cửa sổ có nhãn**, gồm 329 cửa sổ không ngã và 4 cửa sổ ngã. Mô hình phát hiện sự kiện ngã sau mốc tiếp xúc **0,359 giây** và không phát cảnh báo nhầm ở bản ghi không ngã.

Độ trễ trên được đo ở bộ nhận diện chạy trên máy tính. Thời gian từ khi xe ngã đến khi người liên hệ nhận SMS cần được đo trên hệ thống tích hợp. Bộ dữ liệu có bốn tình huống ngã độc lập, vì vậy cần thêm thử nghiệm trên các xe và điều kiện vận hành khác để đánh giá khả năng áp dụng thực tế.

## Cách chạy

### Mô phỏng bằng MATLAB

Mở `Simulate/MotorcycleIMULab` làm thư mục làm việc trong MATLAB R2023a và chạy:

```matlab
outputs = RUN_ALL;
```

Có thể chạy riêng `RUN_ORIGINAL` để tái dựng tín hiệu và `RUN_AUGMENT` để sinh biến thể. Kết quả được tạo cục bộ trong `ORIGINAL/results/` và `AUGMENTED/results/`. [Hướng dẫn mô phỏng](Simulate/MotorcycleIMULab/README.md)

### Huấn luyện và dự đoán trên Windows

Cài Python 3.11 64-bit, mở PowerShell ở gốc repo và chạy:

```powershell
cd ModelAI/MotorcycleFallRF100
.\INSTALL_WINDOWS.bat
.\RUN_TRAIN.bat
```

Khi trình huấn luyện hỏi đường dẫn dữ liệu tăng cường, nhập đường dẫn đến thư mục `Simulate/MotorcycleIMULab` đã chạy mô phỏng. Nhấn Enter để huấn luyện chỉ với dữ liệu đo. Để dự đoán bằng mô hình có sẵn, chỉ định tệp `.joblib` và đường dẫn CSV:

```powershell
.\.venv\Scripts\python.exe predict.py --model "results/RUN_20261110_121039_061836/best_model.joblib" --csv "../../Data/Fall on a slippery straight road section_V1.csv"
```

Lệnh trên minh họa cách dự đoán với một bản ghi có sẵn. [Hướng dẫn ModelAI](ModelAI/MotorcycleFallRF100/README.md)

### Nạp firmware

Mở thư mục `firmware/` bằng VS Code với tiện ích PlatformIO. Chọn môi trường `esp32s3`, cập nhật `upload_port` và `monitor_port` trong [`platformio.ini`](firmware/platformio.ini) theo cổng COM của thiết bị, rồi chọn **Build**, **Upload** và **Serial Monitor**. Cấu hình hiện dùng tốc độ Serial Monitor 115200 baud.

## Nhóm thực hiện

- **Sinh viên thực hiện** — Phạm Văn Nhật và Phạm Hoài An.
- **Giảng viên hướng dẫn** — TS. Nguyễn Văn Hiếu và TS. Trần Thị Minh Hạnh.
- **Đơn vị** — Khoa Điện tử và Trí tuệ nhân tạo, Trường Đại học Bách khoa, Đại học Đà Nẵng.

## Lời cảm ơn và tài liệu tham khảo

Nhóm xin cảm ơn **Abderrahmane Boubezoul, Fabien Dufour, Saïd Bouaziz, Bruno Larnaudie và Stéphane Espié** đã công bố bộ dữ liệu thực nghiệm về các tình huống ngã và sự kiện nguy hiểm của xe hai bánh. Các bản ghi IMU từ công trình này là nguồn dữ liệu để nhóm tái dựng tín hiệu, huấn luyện và đánh giá bộ nhận diện ngã. [Dataset on powered two wheelers fall and critical events detection](https://www.sciencedirect.com/science/article/am/pii/S2352340919301799), *Data in Brief*, 23, 103828 (2019) · [Bản đính chính năm 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7303291/)

Nhóm xin cảm ơn **Mobyen Uddin Ahmed và các đồng tác giả** đã trình bày cách áp dụng Random Forest cho tín hiệu gia tốc và vận tốc góc của xe hai bánh. Công trình này là nguồn tham khảo trực tiếp cho quy trình trích xuất đặc trưng theo cửa sổ và xây dựng bộ phân loại của đồ án. [Data Analysis on Powered Two Wheelers Riders’ Behaviour Using Machine Learning](https://www.es.mdu.se/publications/5392-Data_Analysis_on_Powered_Two_Wheelers_Riders____Behaviour_using_Machine_Learning), ASPAI 2019, tr. 159–163.

Nhóm xin cảm ơn **Leo Breiman** vì công trình *Random Forests*, nền tảng thuật toán của bộ phân loại RF100. [Random Forests](https://doi.org/10.1023/a%3A1010933404324), *Machine Learning*, 45, 5–32 (2001).

### Tài liệu tham khảo khác

- J. Solà (2017). [Quaternion kinematics for the error-state Kalman filter](https://arxiv.org/abs/1711.02508).
- C. de Boor (1972). [On calculating with B-splines](https://doi.org/10.1016/0021-9045%2872%2990080-9).
- MathWorks. [Generate Off-Centered IMU Readings](https://www.mathworks.com/help/nav/ug/generate-off-center-imu-readings.html).
- M. P. Borawake và cộng sự (2026). [Design and Implementation of an IoT-Based Smart Emergency Alert System](https://goldncloudpublications.com/index.php/irjaem/article/download/1610/1506/3181).
