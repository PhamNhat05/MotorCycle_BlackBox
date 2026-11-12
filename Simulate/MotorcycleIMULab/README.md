# MotorcycleIMULab — Tái dựng và tăng cường dữ liệu IMU

Dự án MATLAB gồm hai giai đoạn: `ORIGINAL` tái dựng tín hiệu đo và `AUGMENTED` sinh biến thể. Mười bản ghi đo đi kèm được giữ nguyên nội dung.

## Mục tiêu và phạm vi mô phỏng

Dự án dùng MATLAB để tái dựng tư thế và chuyển động theo thời gian từ dữ liệu
IMU sáu trục của xe máy. Từ chuyển động tái dựng, chương trình tính lại gia tốc
riêng và vận tốc góc tại vị trí cảm biến, rồi so sánh với dữ liệu đo trên từng
trục. Bước tăng cường giữ nguyên chuyển động nguồn và khảo sát ảnh hưởng của
độ lệch cảm biến, vị trí lắp IMU và tác động kết hợp của hai yếu tố.

### Dữ liệu và đánh giá

| Nhóm | Bản ghi ngã | Bản ghi không ngã |
| --- | --- | --- |
| BUILD | Ngã trong cua, ngã ở vòng xuyến, ngã khi nghiêng xe | Tăng tốc đường thẳng, phanh gấp, Fall-like 1, Fall-like 2 |
| TEST | Ngã trên đường thẳng trơn | Tăng tốc trong cua, Fall-like 3 |

Hiệu chuẩn chung được ước lượng từ 7 bản ghi BUILD và cố định trước khi xử lý
3 bản ghi TEST. Mỗi bản ghi TEST cung cấp dữ liệu IMU của chính nó để tái dựng
chuyển động theo cấu hình đã cố định. Phép đánh giá sử dụng toàn bộ thời lượng
của cả 10 bản ghi.

| Tiêu chí theo từng trục | Gia tốc | Vận tốc góc |
| --- | --- | --- |
| RMSE tối đa | Giá trị lớn hơn giữa 0,35 m/s² và 5% biên độ đỉnh–đỉnh | Giá trị lớn hơn giữa 1 °/s và 5% biên độ đỉnh–đỉnh |
| Tương quan Pearson tối thiểu | 0,95 khi độ lệch chuẩn của tín hiệu đo đạt 0,10 m/s² | 0,95 khi độ lệch chuẩn của tín hiệu đo đạt 0,50 °/s |

Chương trình còn kiểm tra trạng thái hữu hạn, chuẩn quaternion và sai số tái tạo
tín hiệu đã làm trơn. Bước tăng cường chạy khi cả 10 bản ghi đạt kiểm tra và sinh
100 biến thể cho mỗi bản ghi. Mỗi biến thể giữ thời gian, nhãn và thông tin truy
ngược về bản ghi nguồn. Khi huấn luyện bộ nhận diện ngã, bản ghi gốc và các biến
thể của nó cần nằm trong cùng nhóm dữ liệu.

Các chỉ số trên đánh giá độ bám của tín hiệu IMU. Xác nhận độ chính xác của quỹ
đạo 3D cần phép đo đối chiếu độc lập. Đánh giá khả năng nhận diện ngã trên các
sự kiện mới cần các bản ghi thực độc lập với dữ liệu huấn luyện.

## Chạy mô phỏng

Đặt thư mục làm việc của MATLAB thành `MotorcycleIMULab`. Dự án dùng MATLAB R2023a với môi trường Java chuẩn. Các biểu đồ SVG được xuất bằng `print(...,'-dsvg')`.

| Lệnh | Công việc |
| --- | --- |
| `RUN_ORIGINAL` | Tái dựng và đánh giá mười bản ghi đo. |
| `RUN_AUGMENT` | Sinh biến thể từ một phiên ORIGINAL hoàn tất. |
| `RUN_ALL` | Tái dựng rồi tăng cường nếu cả mười bản ghi đạt kiểm tra. |

```matlab
outputs = RUN_ALL;
```

Để chạy từng bước:

```matlab
originalResults = RUN_ORIGINAL;
augmentedResults = RUN_AUGMENT(originalResults);
```

`RUN_AUGMENT` không có đối số sẽ chọn phiên ORIGINAL mới nhất. Để chạy các kiểm tra tổng hợp trên dữ liệu mô phỏng, dùng:

```matlab
checks = CHECK_PROJECT;
```

## Cấu trúc thư mục

| Đường dẫn | Nội dung |
| --- | --- |
| `ORIGINAL/data/build/`, `ORIGINAL/data/test/` | Bảy bản ghi BUILD và ba bản ghi TEST. |
| `ORIGINAL/config/INPUT_MANIFEST.json` | Mã nguồn dữ liệu, nhãn, mốc thời gian, số dòng và mã kiểm tra. |
| `ORIGINAL/ORIGINAL_CONFIG.m` | Cấu hình tái dựng và xuất kết quả. |
| `ORIGINAL/src/calibration/` | Ước lượng độ lệch nền của con quay từ nhóm BUILD. |
| `ORIGINAL/src/conditioning/` | Khớp spline và tính đạo hàm số. |
| `ORIGINAL/src/reconstruction/` | Tính quaternion, chuyển động liên tục và tín hiệu IMU. |
| `ORIGINAL/src/evaluation/` | Chỉ số độ bám và điều kiện hoàn tất. |
| `ORIGINAL/src/io/`, `plotting/`, `reporting/` | Đọc và ghi tệp, vẽ biểu đồ và tạo báo cáo. |
| `ORIGINAL/src/workflow/`, `validation/` | Điều phối quy trình và kiểm tra số trên dữ liệu tổng hợp. |
| `AUGMENTED/AUGMENTATION_CONFIG.m` | Số lượng biến thể, giới hạn thay đổi và thiết lập hiển thị. |
| `AUGMENTED/src/planning/`, `generation/` | Lập kế hoạch tái lập được và tính IMU với vị trí, độ lệch mới. |
| `AUGMENTED/src/evaluation/`, `io/` | Tính sai số, xuất dữ liệu và xác minh khi chạy tiếp. |
| `AUGMENTED/src/plotting/`, `reporting/` | Vẽ biểu đồ và tạo báo cáo từng biến thể. |
| `AUGMENTED/src/workflow/`, `validation/` | Điều phối, lập chỉ mục và kiểm tra số lượng, giới hạn. |
| `ORIGINAL/results/`, `AUGMENTED/results/` | Kết quả được tạo cục bộ theo từng phiên. |

Các đường dẫn rút gọn trong bảng cùng nằm dưới `src/` của giai đoạn tương ứng. MATLAB chỉ thêm thư mục mã nguồn vào đường dẫn tìm kiếm. Các hàm tính toán và tạo báo cáo dùng chung nằm ở `ORIGINAL/src/`. [Hướng dẫn đọc mã](CODE_GUIDE.md)

## Kết quả tái dựng ORIGINAL

Chương trình dùng các đoạn đầu của bảy bản ghi BUILD để ước lượng hiệu chuẩn rồi khóa cấu hình trước khi đánh giá TEST. Phép đánh giá giữ toàn bộ dữ liệu nguồn, gồm 24 dòng khởi đầu có giá trị bằng không.

Mở `REPORT.html` trong `ORIGINAL/results/RUN_.../`. Mỗi thư mục `records/<parent>/` chứa:

| Tệp | Nội dung |
| --- | --- |
| `MODEL.mat` | Mô hình tái dựng dùng làm đầu vào tăng cường. |
| `FULL_SIGNAL_COMPARISON.csv` | Tín hiệu đo và tín hiệu tái dựng trên sáu trục. |
| `FULL_STATE.csv` | Trạng thái chuyển động và các đại lượng góc. |
| `FULL_RECORD_FIT.svg`, `FULL_RECORD_FIT.png` | Biểu đồ so sánh dạng vectơ và ảnh độ phân giải cao. |
| `AXIS_FIT.csv` | RMSE, MAE, sai số cực đại, tương quan và độ bám từng trục. |
| `QUALITY.json` | Tiêu chí chất lượng và dấu xác nhận hoàn tất. |

`ALL_AXIS_FIT.csv` tổng hợp 60 dòng, tương ứng mười bản ghi và sáu trục. Trạng thái chuyển động được lưu để tính IMU và sinh biến thể theo vị trí.

## Kết quả tăng cường AUGMENTED

| Nhóm | Mã biến thể | Mỗi bản ghi | Tổng cộng |
| --- | --- | ---: | ---: |
| Chỉ đổi độ lệch | 001–034 | 34 | 340 |
| Chỉ đổi vị trí | 035–067 | 33 | 330 |
| Đổi vị trí và độ lệch | 068–100 | 33 | 330 |
| **Tổng** | **001–100** | **100** | **1.000** |

Các biến thể giữ mốc thời gian và lưới lấy mẫu 1.000 Hz của bản ghi nguồn. Bộ dữ liệu đầy đủ có 100.810.700 dòng dữ liệu tăng cường, chưa tính tiêu đề CSV.

Ví dụ: `AUGMENTED/results/RUN_.../records/fall_curve/position_only/variant_035.csv`.

Mỗi biến thể có CSV, biểu đồ SVG và PNG, trang HTML, chỉ số sáu trục, JSON ghi tham số và dấu xác nhận hoàn tất. Mở `INDEX.html`, chọn bản ghi nguồn rồi chọn báo cáo biến thể. `VARIANT_MANIFEST.csv` ghi 1.000 bộ tham số. `ALL_AXIS_METRICS.csv` chứa 6.000 dòng chỉ số khi phiên hoàn tất.

### Đọc biểu đồ và báo cáo

Báo cáo dùng nền trắng, chữ tối, cỡ chữ nội dung 18 px và cỡ chữ bảng 17 px. Biểu đồ SVG giữ độ nét khi phóng to. Ảnh PNG được xuất ở 220 DPI.

- **Readable size** hiển thị ở cỡ đọc mặc định và cho phép cuộn ngang.
- **Fit width** thu biểu đồ vừa chiều rộng trang.
- **Open full-size chart** mở tệp SVG.
- **Download high-resolution PNG** tải ảnh PNG.

Biểu đồ có sáu hàng cho sáu trục và ba cột. Cột đầu so sánh bản ghi đo với một biến thể theo toàn bộ thời lượng. Cột thứ hai phóng to một khoảng thời gian ở tần số lấy mẫu gốc. Cột cuối tách chênh lệch tổng, ảnh hưởng vị trí, ảnh hưởng độ lệch và sai số tái dựng cơ sở. Tiêu đề biểu đồ và báo cáo ghi độ dịch XYZ, vị trí mới và sáu độ lệch. Trang HTML có thêm bảng sai số theo toàn bộ thời lượng.

[AUGMENTED/docs/REPORT_PREVIEW.html](AUGMENTED/docs/REPORT_PREVIEW.html) minh họa giao diện báo cáo bằng bản xem trước tạo từ Python.

## Cấu hình tăng cường

| Tham số | Giá trị mặc định |
| --- | --- |
| Độ lệch gia tốc bổ sung | ±10 m/s² trên mỗi trục. |
| Độ lệch con quay bổ sung | ±0,2 °/s trên mỗi trục. |
| Độ dịch vị trí trong hệ thân | Độ dài vectơ tối đa 0,5 m. |
| Vị trí IMU danh định | `[0.05 0 -0.05]` m. |
| Vị trí mới | `nominal_position + position_shift`. |
| Hướng lắp IMU | Giữ nguyên. |
| Độ lệch trong một biến thể | Hằng số suốt bản ghi. |
| Hạt giống ngẫu nhiên | `20261109`. |

Ví dụ, dịch +0,5 m trên trục X cho vị trí mới `[0.55 0 -0.05]` m. Các biến thể dịch riêng từng trục theo hai chiều giúp quan sát ảnh hưởng của tham số. Các biến thể còn lại phối hợp nhiều trục bằng bộ sinh số ngẫu nhiên MATLAB có hạt giống cố định. Chuỗi số của MATLAB và NumPy có thể khác nhau khi dùng cùng hạt giống.

## Chạy tiếp phiên bị gián đoạn

```matlab
RUN_ORIGINAL('resume')
RUN_AUGMENT([], 'resume')
RUN_ALL('resume')
```

Bạn có thể chỉ định thư mục phiên cần chạy tiếp. `RUN_ALL('resume')` chỉ dùng phiên tăng cường mới nhất nếu nó thuộc phiên ORIGINAL đã chọn. Tạo tệp `STOP_AFTER_CURRENT_TASK.txt` trong thư mục kết quả đang chạy để dừng sau bản ghi hoặc biến thể hiện tại. Xóa tệp đó trước khi chạy tiếp.

Chương trình tái sử dụng các đầu ra đã hoàn tất có mã định danh và mã kiểm tra khớp. Khi sửa mã hoặc cấu hình, tạo phiên mới cho giai đoạn bị ảnh hưởng. Thay đổi riêng cấu hình tăng cường vẫn cho phép dùng lại phiên ORIGINAL đã hoàn tất. Hãy tạo phiên mới khi chuyển từ phiên bản có cấu trúc thư mục hoặc tên hàm cũ.

## Phương pháp và kiểm tra

Tăng cường giữ nguyên chuyển động tái dựng rồi tính ảnh hưởng của dịch chuyển vị trí và độ lệch:

```text
position_effect = (alpha x displacement + omega x (omega x displacement)) * R_BS
augmented_acc   = baseline_acc + position_effect + acceleration_bias_delta
augmented_gyro  = baseline_gyro + gyroscope_bias_delta
```

Xem quy ước hệ tọa độ và gia tốc riêng trong [tài liệu phương pháp](ORIGINAL/docs/MATHEMATICS.md). Giới hạn tăng cường là các tham số thí nghiệm. Biến thể từ ba bản ghi TEST của mô phỏng được đánh dấu để kiểm tra độ bền cảm biến trên dữ liệu giữ riêng.

[Thông tin kiểm tra](ORIGINAL/docs/VALIDATION.json) ghi các kiểm tra bảo toàn dữ liệu gốc, cú pháp MATLAB, đường dẫn phụ thuộc và định dạng báo cáo. Các kiểm tra `CHECK_PROJECT` và tiêu chí chất lượng từng bước được thực thi trong phiên MATLAB của người dùng.
