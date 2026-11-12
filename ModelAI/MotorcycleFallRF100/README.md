# MotorcycleFallRF100

Dự án Python 3.11 dùng dữ liệu IMU của MotorcycleIMULab để nhận diện ngã xe
máy. Mỗi bộ phân loại Random Forest sử dụng **100 cây**, độ sâu tối đa 8
và 24 đặc trưng đầu vào. Dự án kèm 10 tệp CSV đo gốc, giữ nguyên nội dung.
MATLAB dùng để sinh dữ liệu tăng cường. Phần huấn luyện và dự đoán chạy bằng Python.

## Bắt đầu trên Windows

1. Cài Python 3.11 bản 64 bit. Mở thư mục dự án và chạy
   `INSTALL_WINDOWS.bat` để tạo môi trường và cài thư viện qua Internet.
2. Để huấn luyện với dữ liệu tăng cường, chạy `RUN_ORIGINAL` và `RUN_AUGMENT`
   trong dự án MATLAB MotorcycleIMULab.
3. Chạy `RUN_TRAIN.bat`. Khi được hỏi, nhập đường dẫn thư mục gốc
   MotorcycleIMULab, bỏ dấu ngoặc kép. Chương trình tìm phiên tăng cường qua
   `AUGMENTED/results/LATEST_RUN.txt`. Bạn cũng có thể nhập đường dẫn đến
   thư mục `AUGMENTED/results/RUN_...` cụ thể.
4. Khi terminal hiện `COMPLETE`, mở `results/RUN_.../REPORT.html` để xem báo cáo.
5. Chạy `RUN_PREDICT.bat` để dự đoán trên CSV theo định dạng đo gốc hoặc định
   dạng do trình mô phỏng xuất.

Nhấn Enter ở bước nhập đường dẫn để huấn luyện chỉ với dữ liệu đo. Đường dẫn
tăng cường sai hoặc phiên xuất chưa hoàn tất sẽ báo lỗi. Chạy `RUN_CHECK.bat`
để kiểm tra dữ liệu gốc và chạy các ca kiểm tra tổng hợp.

Ca kiểm tra đầy đủ dưới đây tạo 1.000 CSV tổng hợp cỡ nhỏ trong thư mục tạm,
kiểm tra cách chia 600/200/200, phát hiện tệp bị sửa hoặc xuất thiếu, huấn
luyện RF100, ghi báo cáo rồi dọn dữ liệu tạm:

```bat
.venv\Scripts\python.exe tests\augmentation_fixture_check.py
```

## Lệnh Python tương đương

```bat
py -3.11 -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
.venv\Scripts\python.exe train.py --augmentation-dir "D:\Project\MotorcycleIMULab"
```

Nếu đã chuyển phiên tăng cường ra khỏi dự án MATLAB, chỉ định cả phiên tái
dựng gốc tương ứng:

```bat
.venv\Scripts\python.exe train.py --augmentation-dir "D:\Saved\Augmented_RUN" --original-run "D:\Saved\Original_RUN"
```

Để huấn luyện chỉ với dữ liệu đo:

```bat
.venv\Scripts\python.exe train.py
```

Thêm `--allow-partial` nếu muốn dùng phiên tăng cường đang xuất dở. Số lượng
khi đó dựa trên các cặp CSV và JSON đã hoàn tất. Một phiên đầy đủ gồm 100 biến
thể trên mỗi bản ghi nguồn, chia thành 34 biến thể độ lệch, 33 biến thể vị trí
và 33 biến thể kết hợp.

## Phân chia dữ liệu

| Nhóm AI | Bản ghi gốc | Ngã / không ngã | Biến thể dự kiến | Tổng số tệp khi tăng cường đầy đủ |
| --- | ---: | ---: | ---: | ---: |
| TRAIN | 6 | 2 / 4 | 600 | 606 |
| VALIDATION | 2 | 1 / 1 | 200 | 202 |
| TEST | 2 | 1 / 1 | 200 | 202 |

- **TRAIN** — `fall_curve`, `fall_leaning`, `acceleration_straight`, `harsh_braking_straight`, `fall_like_1`, `fall_like_2`.
- **VALIDATION** — `fall_roundabout`, `acceleration_curve`.
- **TEST** — `fall_slippery_straight`, `fall_like_3`.

Tỷ lệ 7 BUILD / 3 TEST của mô phỏng được lưu để truy xuất nguồn gốc. Bộ
phân loại dùng cách chia 6/2/2 trong `config/parents.json`, theo bản ghi
gốc thay vì chia ngẫu nhiên theo cửa sổ. Mọi biến thể đi cùng nhóm với bản
ghi nguồn. Hai bản ghi đo VALIDATION dùng để chọn mô hình và ngưỡng. Hai
bản ghi đo TEST dùng cho đánh giá chính. Các biến thể VALIDATION và TEST
dùng để khảo sát độ bền trước thay đổi cảm biến sau khi chốt mô hình.

## Huấn luyện và chọn mô hình

Khi có dữ liệu tăng cường, dự án huấn luyện hai ứng viên:

- `real_only__rf100` dùng sáu bản ghi đo TRAIN.
- `mixed__rf100` dùng sáu bản ghi đo TRAIN và các biến thể đã hoàn tất của chúng.

Hai ứng viên cùng dùng 100 cây, độ sâu tối đa 8, mỗi lá tối thiểu một mẫu,
lấy mẫu bootstrap, xét số đặc trưng bằng căn bậc hai tổng số đặc trưng khi
chia nút, seed 42 và 24 đặc trưng đầu vào. Trọng số huấn luyện cân bằng theo
lớp, bản ghi nguồn, loại dữ liệu đo hoặc tăng cường và từng bản ghi biến thể.

Trên VALIDATION, thứ tự ưu tiên là tỷ lệ phát hiện sự kiện gắn với mốc tiếp
xúc, điểm F2, ít cảnh báo nhầm hơn và độ trễ không âm ngắn hơn. Khi các tiêu
chí bằng nhau, ưu tiên mô hình hỗn hợp. Nếu các ngưỡng cho kết quả bằng nhau,
ưu tiên ngưỡng cao hơn. Quyết định được ghi cùng mã băm trước khi đọc tín
hiệu TEST. TEST chỉ dùng để đánh giá các ứng viên đã cố định.

## Định dạng dữ liệu tăng cường

```text
AUGMENTED/results/RUN_.../
    VARIANT_MANIFEST.csv
    ORIGINAL_RUN.json
    records/<parent>/<group>/variant_001.csv
    records/<parent>/<group>/variant_001.json
    records/<parent>/<group>/variant_001.complete.json
ORIGINAL/results/<matching-run>/FROZEN_CONFIGURATION.json
```

Tiêu đề CSV là `Time_s,Ax_m_s2,Ay_m_s2,Az_m_s2,Gx_deg_s,Gy_deg_s,Gz_deg_s`.
Trình nhập lấy đường dẫn và số lượng từ manifest, rồi đối chiếu dấu hoàn
tất, mã băm của CSV, cấu hình biến thể và mô hình nguồn, cùng mốc thời gian,
nhóm biến thể, giới hạn nhiễu chỉnh và cấu hình đã khóa.

**Hiệu chuẩn dùng chung.** Trình mô phỏng ước lượng độ lệch nền của con quay
từ bảy bản ghi BUILD, trong đó có một bản ghi thuộc VALIDATION của AI. Khi
nhập dữ liệu, chương trình tính lại đóng góp của độ lệch này trong thành phần
gia tốc hướng tâm do dịch vị trí, sử dụng ước lượng từ sáu bản ghi TRAIN.
Hiệu chỉnh độ lệch hằng giữ nguyên gia tốc góc và được áp dụng khi nhập,
giữ nguyên nội dung CSV đã xuất. Chi tiết lưu trong
`AUGMENTATION_REBASE_INFO.json` và `DATASET_AUDIT.csv`.
[Phương pháp và công thức](docs/METHOD.md)

## Kết quả đầu ra

| Tệp hoặc thư mục | Nội dung |
| --- | --- |
| `REPORT.html` | Báo cáo, bảng và biểu đồ SVG. |
| `DATA_SPLIT.csv`, `SPLIT_SUMMARY.csv` | Phân nhóm và số lượng bản ghi dự kiến, thực tế. |
| `DATASET_AUDIT.csv` | Mã băm nguồn, nhóm bản ghi, số cửa sổ đặc trưng và thông tin hiệu chỉnh. |
| `VALIDATION_CANDIDATES.csv`, `VALIDATION_THRESHOLD_SEARCH.csv` | Kết quả chọn mô hình và ngưỡng. |
| `MODEL_SELECTION_FROZEN.json` và tệp `.sha256` | Quyết định đã chốt trước khi đọc dữ liệu TEST. |
| `TEST_COMPARISON_PREDECLARED_MODELS.csv` | So sánh trên TEST giữa các ứng viên đã xác định trước. |
| `EVALUATION_SUMMARY.csv`, `CLASS_METRICS.csv`, `PER_RECORD_METRICS.csv` | Chỉ số tổng hợp, theo lớp và theo bản ghi. |
| `predictions/original/`, `predictions/augmented/` | Dự đoán theo cửa sổ cho bản ghi gốc và biến thể được đánh giá. |
| `ORIGINALS_SEQUENTIAL_TIMELINE.csv` | Ghép 10 phiên độc lập lên một trục thời gian hiển thị. Bộ lọc, bộ đệm và trạng thái cảnh báo được đặt lại giữa các tệp. |
| `best_model.joblib`, `BEST_MODEL_INFO.json`, `models/` | Mô hình đã huấn luyện và thông tin liên quan. |
| `feature_cache/`, `RUN_LOG.txt`, `STAGES.jsonl` | Bộ nhớ đệm đặc trưng, nhật ký và thứ tự các bước. |

Báo cáo có ma trận nhầm lẫn cho các nhóm được đánh giá. Chỉ số TRAIN và chỉ
số gộp có chứa dữ liệu đã dùng để khớp mô hình. TEST thực có một sự kiện ngã
độc lập, dù sự kiện này có thể có 100 biến thể cảm biến.

## Dự đoán theo tệp và theo luồng

Đầu vào dùng gia tốc m/s², vận tốc góc °/s và thời gian tính bằng giây.
Dấu thời gian phải tăng đều. Tần số nguồn phải là bội nguyên của 100 Hz.
Chương trình đọc được dữ liệu đo gốc phân cách bằng tab, mã hóa Latin-1 và
CSV tăng cường. Tiêu đề `time,Ax,Ay,Az,Gx,Gy,Gz` và các tên thay thế
`Rx,Ry,Rz` cũng được hỗ trợ.

```bat
.venv\Scripts\python.exe predict.py --csv "D:\Signals\new.csv"
.venv\Scripts\python.exe predict.py --csv "D:\Signals\new.csv" --stream
```

`--stream` phát lại dữ liệu theo từng mẫu. Chế độ đọc toàn tệp dùng cùng bộ
lọc nhân quả, pha lấy mẫu giảm, cửa sổ chỉ chứa dữ liệu quá khứ và đặc trưng.
API `StreamingPredictor` trong `rf100/stream.py` nhận từng mẫu hoặc từng
khối từ nguồn thu trực tiếp. Điểm số, nhãn và trạng thái cảnh báo có sau cửa
sổ đầy đủ đầu tiên, sau đó cập nhật mỗi 0,5 giây. Phần này phục vụ huấn luyện
và kiểm tra trên máy tính.

Chỉ định tệp mô hình đã huấn luyện khi dự đoán bằng mô hình có sẵn trong repo:

```bat
.venv\Scripts\python.exe predict.py --model "results\RUN_20261110_121039_061836\best_model.joblib" --csv "D:\Signals\new.csv" --out "new_predictions"
```

## Dừng và chạy tiếp

Nhấn Ctrl+C để dừng. Khi chạy tiếp, dùng cùng đường dẫn đầu ra:

```bat
.venv\Scripts\python.exe train.py --augmentation-dir "D:\Project\MotorcycleIMULab" --out "results\RUN_..." --resume
```

Chương trình tái sử dụng bộ nhớ đệm đặc trưng đã xác minh và bắt đầu lại bước
khớp mô hình nếu bước đó chưa hoàn tất. Khi dữ liệu nguồn, nhãn, manifest,
cấu hình hoặc mã đặc trưng thay đổi, cần tính lại phần liên quan hoặc tạo
phiên mới.

## Tài liệu đi kèm

- [Phương pháp](docs/METHOD.md)
- [Đặc trưng đầu vào](docs/FEATURES.md)
- [Tài liệu tham khảo](docs/REFERENCES.md)
- [Hướng dẫn đọc mã](docs/CODE_GUIDE.md)

`example_results/` chứa kết quả một phiên huấn luyện chỉ với 10 bản ghi đo.
Đợt kiểm tra trên Linux chưa chạy các tệp lệnh Windows và trình sinh dữ liệu
MATLAB. Tài liệu nguồn gốc dữ liệu đi kèm ghi nhận rằng phiên bản dữ liệu đã
đính chính của nhà xuất bản còn chờ đối chiếu.
