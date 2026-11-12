# Hộp đen thông minh cho xe máy

Đồ án PBL5 xây dựng nguyên mẫu hộp đen thu tín hiệu quán tính của xe máy và đánh giá khả năng nhận diện ngã bằng mô hình Random Forest. Khi xác nhận ngã, thiết bị được thiết kế để gửi SMS kèm tọa độ GPS đến số liên hệ đã cài đặt. Phần nhúng hiện thực hiện lấy mẫu và lưu dữ liệu IMU. Mô hình nhận diện đã được đánh giá trên máy tính. Suy luận trên ESP32-S3, định vị và gửi SMS là các phần cần tích hợp và kiểm thử.

## Cấu trúc kho mã

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

## Nhóm thực hiện và nguồn dữ liệu

- **Sinh viên thực hiện** — Phạm Văn Nhật và Phạm Hoài An.
- **Giảng viên hướng dẫn** — TS. Nguyễn Văn Hiếu và TS. Trần Thị Minh Hạnh.
- **Đơn vị** — Khoa Điện tử và Trí tuệ nhân tạo, Trường Đại học Bách khoa, Đại học Đà Nẵng.
- **Dữ liệu IMU** — A. Boubezoul và cộng sự, *Dataset on powered two wheelers fall and critical events detection*, Data in Brief, 2019. [Bài báo dữ liệu](https://doi.org/10.1016/j.dib.2019.103828) · [Bản đính chính](https://doi.org/10.1016/j.dib.2020.105577)
