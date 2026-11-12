# ORIGINAL — Tái dựng tín hiệu IMU

Dữ liệu đo nằm trong `data/build` và `data/test`. Chạy `RUN_ORIGINAL` từ thư mục gốc MotorcycleIMULab. Kết quả được ghi vào `results/RUN_.../`. Mở `REPORT.html` của phiên để xem kết quả.

Chương trình ước lượng hiệu chuẩn chung từ bảy bản ghi BUILD, cố định cấu hình rồi xử lý ba bản ghi TEST bằng cấu hình đó. Đầu ra gồm tín hiệu và trạng thái chuyển động theo toàn bộ thời lượng, chỉ số độ bám và biểu đồ SVG/PNG. Phiên bản này tập trung xuất dữ liệu và biểu đồ.

Mã nguồn được tổ chức theo nhiệm vụ hiệu chuẩn, xử lý tín hiệu, tái dựng, đánh giá, đọc ghi dữ liệu, vẽ biểu đồ, tạo báo cáo, kiểm tra và điều phối. Bước AUGMENTED dùng lại các hàm tính toán và báo cáo dùng chung.
