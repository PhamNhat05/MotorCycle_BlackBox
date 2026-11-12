# AUGMENTED — Tăng cường dữ liệu IMU

Đầu vào là phiên ORIGINAL đã hoàn tất với cả mười bản ghi đạt tiêu chí kiểm tra. Chạy `RUN_AUGMENT(originalResults)` từ thư mục gốc MotorcycleIMULab. Bỏ đối số để chọn phiên ORIGINAL mới nhất. Kết quả được ghi vào `results/RUN_.../`.

Mở `INDEX.html` của phiên, chọn bản ghi nguồn rồi mở báo cáo của biến thể cần xem. Mỗi bản ghi nguồn có 34 biến thể chỉ đổi độ lệch cảm biến, 33 biến thể chỉ đổi vị trí và 33 biến thể kết hợp.

Mỗi biến thể có CSV đầy đủ, biểu đồ SVG, ảnh PNG độ phân giải cao, trang HTML, bảng chỉ số sáu trục, tệp JSON ghi tham số và dấu xác nhận hoàn tất. `AUGMENTATION_CONFIG.m` quy định số lượng, giới hạn, hạt giống ngẫu nhiên và chất lượng hiển thị.

Các chức năng sinh dữ liệu, tính chỉ số, vẽ biểu đồ, tạo báo cáo và xác minh kết quả nằm trong các thư mục mã nguồn riêng. Mỗi biến thể dùng lại mô hình và chuyển động của bản ghi gốc.

Báo cáo tách chênh lệch thành ba thành phần:

```text
augmented - measured = position_effect + bias_effect + (baseline - measured)
```

Thay đổi vị trí IMU khi giữ nguyên hướng lắp giữ tín hiệu con quay bằng tín hiệu tái dựng cơ sở. Chênh lệch còn lại so với con quay đo được là sai số tái dựng cơ sở.
