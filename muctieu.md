# Mục tiêu dự án tái dựng chuyển động 3D và tăng cường dữ liệu IMU xe máy

**Cập nhật: 01/11/2026.**

Tài liệu này cập nhật mục tiêu theo hướng V4 FINAL đã thống nhất: tái dựng từ dữ liệu IMU thật bằng MATLAB, kiểm tra theo phân chia 7 BUILD : 3 TEST, sau đó tăng cường dữ liệu bằng thay đổi bias và vị trí đặt IMU.

## 1. Mục tiêu tổng quát

Xây dựng một quy trình **tái dựng động học bằng MATLAB**, dùng dữ liệu IMU sáu trục của các tình huống xe máy để tìm chuyển động vị trí và tư thế theo thời gian. Từ chuyển động đó, tính lại IMU ảo sao cho bám dữ liệu thật tốt nhất có thể trên cả sáu trục.

Sau khi quy trình đạt các tiêu chí trên 7 file xây dựng và 3 file kiểm tra với cấu hình dùng chung đã khóa, sử dụng những chuyển động đã tái dựng của 7 BUILD để tạo thêm các quan sát IMU bằng cách thay đổi có kiểm soát:

- Bias của gia tốc kế và con quay hồi chuyển.
- Vị trí đặt IMU trong hệ tọa độ thân của mô hình.
- Sự kết hợp giữa hai thay đổi trên.

Các mẫu tăng cường phục vụ nghiên cứu dữ liệu cho hệ thống hộp đen và nhận biết ngã xe máy. Chúng là biến thể cảm biến của những sự kiện đã có; việc sinh tình huống cơ học mới bằng thay đổi ma sát, phanh, lực va chạm hoặc tham số động lực học cần một hướng kiểm chứng riêng.

## 2. Dữ liệu và cách chia 7:3

Tập dữ liệu gồm **10 bản ghi thực tế: 4 ngã và 6 không ngã**. Phân chia theo bản ghi gốc, giữ cố định trong quá trình phát triển và đánh giá.

| Vai trò | Số file | Tình huống |
|---|---:|---|
| BUILD — ngã | 3 | Ngã trong cua (`curve`), ngã trong vòng xuyến (`roundabout`), ngã khi nghiêng xe (`leaning`) |
| BUILD — không ngã | 4 | Tăng tốc đường thẳng (`acc_straight`), bản ghi phanh gấp (`hard_brake`), Fall-like 1 (`fall_like_1`), Fall-like 2 (`fall_like_2`) |
| TEST — ngã | 1 | Ngã trên đường thẳng trơn (`slippery`) |
| TEST — không ngã | 2 | Tăng tốc trong cua (`acc_curve`), Fall-like 3 (`fall_like_3`) |

**7 BUILD** được dùng để phát triển phương pháp, xác định hoặc khai báo cấu hình chung, hiệu chuẩn chung và chọn các thiết lập tái dựng. **3 TEST** được giữ riêng khỏi các bước lựa chọn đó.

Phạm vi triển khai hiện tại là các cửa sổ sự kiện đã chốt: khoảng **0,8 giây với file ngã** và **1,2 giây với file không ngã**. Phải công bố đúng cửa sổ, số mẫu và thời gian gốc; kết quả trên các cửa sổ này chưa đại diện cho toàn bộ thời lượng của 10 bản ghi.

## 3. Nguyên tắc tái dựng

### 3.1. Chuyển động và IMU phải nhất quán

Đầu vào là sáu kênh IMU thật:

- **Ax, Ay, Az:** gia tốc riêng trong hệ tọa độ cảm biến, đơn vị m/s².
- **Rx, Ry, Rz:** vận tốc góc trong hệ tọa độ cảm biến, đơn vị °/s.

Từ các kênh này, quy trình suy ra tư thế và chuyển động vị trí. IMU ảo phải được tính từ chính chuyển động tái dựng, có xét trọng lực, phép đổi hệ tọa độ, vị trí lắp và hướng lắp IMU.

Video 3D sử dụng cùng mô hình chuyển động với phép tính IMU. Không tạo hoạt ảnh riêng để làm video trông đúng trong khi tín hiệu được sinh từ một chuyển động khác.

Ưu tiên giữ được dạng sóng, biên độ, thời điểm diễn biến và các dao động của tín hiệu. Mật độ nút spline và mức làm trơn phải đủ để biểu diễn những thành phần cần tái dựng. Chưa xác định được một thành phần là nhiễu thì chưa có cơ sở tự loại bỏ thành phần đó để gọi là tái dựng tốt dữ liệu gốc.

Độ bám được tạo ra qua việc tìm chuyển động phù hợp; không sao chép trực tiếp sáu kênh thật hoặc cộng lại nguyên phần dư đo vào đầu ra để làm đẹp kết quả.

### 3.2. Phân biệt cấu hình chung với chuyển động riêng

| Nhóm | Nội dung | Cách sử dụng |
|---|---|---|
| Cấu hình dùng chung | Bias gốc, vị trí/hướng lắp danh định, hình học mô hình, quy tắc khởi tạo, cấu hình spline, hệ số làm trơn và tiêu chí đánh giá | Xác định hoặc khai báo bằng BUILD/thông tin độc lập, sau đó khóa trước TEST |
| Kết quả riêng của từng file | Quỹ đạo, tư thế và các hệ số biểu diễn chuyển động của sự kiện đó | Được tìm từ IMU của chính file bằng phương pháp chung đã khóa |
| Tham số tăng cường | Độ dịch bias và độ dịch vị trí IMU | Chỉ sử dụng sau khi BUILD và TEST đều đạt; áp dụng cho các chuyển động BUILD đã lưu |

Phải ghi rõ tham số nào được ước lượng, tham số nào là giá trị giả định. Việc có một cấu hình dùng chung chưa có nghĩa toàn bộ hình học, bias, vận tốc ban đầu hoặc các đặc tính vật lý đã được nhận dạng từ dữ liệu.

## 4. Quy trình thực hiện và ý nghĩa của TEST

1. Đọc dữ liệu, kiểm tra đơn vị, thời gian, phân chia 7:3 và các cửa sổ sự kiện.
2. Dùng 7 BUILD để hiệu chuẩn và hoàn thiện cấu hình tái dựng dùng chung.
3. Tái dựng 7 BUILD, xuất đầy đủ kết quả và kiểm tra từng file, từng trục. Chỉ chuyển bước khi cả 7 BUILD đạt.
4. Khóa cấu hình chung, chạy tái dựng 3 TEST bằng đúng cấu hình và quy tắc đã chốt.
5. Đối chiếu IMU ảo với IMU thật của từng TEST. Nếu một TEST chưa đạt, ghi rõ nguyên nhân và giữ bước tăng cường ở trạng thái chưa được mở.
6. Khi cả 7 BUILD và 3 TEST đạt, sinh dữ liệu tăng cường từ 7 BUILD.

**TEST trong hướng này là kiểm tra khả năng tái dựng trên các bản ghi không dùng để chọn cấu hình chung.** Mỗi TEST vẫn cung cấp IMU của chính nó để tìm chuyển động riêng; chương trình không được điều chỉnh bias chung, cấu hình spline, mức làm trơn hoặc ngưỡng đạt theo file TEST.

Kết quả TEST có thể cho thấy phương pháp tái dựng hoạt động trên bản ghi mới với cấu hình chung cố định. Nó chưa chứng minh khả năng dự báo chuyển động khi chưa có IMU của sự kiện, quỹ đạo 3D đúng duy nhất hoặc một mô hình động lực học đã được kiểm chứng.

Nếu thay đổi phương pháp/cấu hình sau khi đã xem kết quả TEST, phải khai báo lần sửa và phạm vi dữ liệu đã sử dụng, thay vì tiếp tục trình bày TEST đó như một đánh giá chưa từng được tham khảo.

## 5. Tiêu chí đánh giá độ bám

Mục tiêu là giảm sai số trên **từng trục của từng file**, đồng thời giữ dạng tín hiệu và thời điểm diễn biến. Không dùng sai số trung bình của nhiều trục để che một trục chưa đạt, và không gộp trực tiếp đơn vị gia tốc với đơn vị vận tốc góc.

Bộ tiêu chí hiện tại của V4 FINAL gồm:

| Đại lượng | Ax, Ay, Az | Rx, Ry, Rz |
|---|---|---|
| Ngưỡng RMSE | `max(0,35 m/s²; 5% × biên độ đỉnh–đỉnh của trục)` | `max(1 °/s; 5% × biên độ đỉnh–đỉnh của trục)` |
| Tương quan Pearson | Tối thiểu 0,95 khi độ lệch chuẩn của tín hiệu thật ≥ 0,10 m/s² | Tối thiểu 0,95 khi độ lệch chuẩn của tín hiệu thật ≥ 0,50 °/s |

Trục gần hằng vẫn phải đạt RMSE; chỉ bỏ tiêu chí tương quan khi độ biến thiên thấp hơn mức đã khai báo. Đây là các ngưỡng kỹ thuật của dự án, không phải giới hạn sai số được chứng nhận của IMU.

Mỗi file còn phải có nghiệm hữu hạn, bộ giải báo thành công, tư thế hợp lệ, công thức IMU được kiểm tra độc lập và hình học nằm trong giới hạn đã đặt. Phép so sánh giữ nguyên cửa sổ và trục thời gian; không dịch tín hiệu hoặc lọc riêng đường thật/ảo sau khi chạy để cải thiện điểm số.

Chỉ đánh dấu một file đạt khi tất cả sáu trục và các kiểm tra đi kèm đều đạt. Các chỉ số, điều kiện đạt/chưa đạt và nguyên nhân sai lệch phải được xuất ra để kiểm tra lại.

## 6. Tăng cường dữ liệu sau khi vượt kiểm tra

### 6.1. Thay đổi bias

Bias là **một bộ sáu độ lệch cộng**, tương ứng sáu trục IMU. Mỗi mẫu tăng cường sử dụng:

```text
bias_mới = bias_gốc + delta_bias
IMU_mới = IMU_lý_tưởng_tại_vị_trí_mới + bias_mới
```

Khoảng thay đổi mặc định quanh bias gốc:

| Nhóm trục | Khoảng delta trên mỗi trục |
|---|---:|
| Ax, Ay, Az | −0,10 đến +0,10 m/s² |
| Rx, Ry, Rz | −0,20 đến +0,20 °/s |

Mỗi mẫu chọn một vector bias và **giữ cố định trong toàn bộ mẫu**. Đây là biến thể bias hằng, không phải nhiễu ngẫu nhiên thay đổi ở từng thời điểm. Bias được cộng đúng một lần; thay đổi bias trong bước tăng cường không làm thay đổi chuyển động nguồn.

Các khoảng trên là cấu hình tăng cường đã khai báo, chưa phải khoảng bias thực tế được xác nhận bằng đo hiệu chuẩn hoặc datasheet của phần cứng. Khi có bằng chứng thực nghiệm phù hợp, có thể cập nhật phạm vi và lưu rõ cấu hình của từng bộ dữ liệu.

### 6.2. Dịch vị trí IMU

Giữ nguyên chuyển động xe và thay đổi vị trí cố định của IMU trong hệ thân mô hình:

```text
vị_trí_IMU_mới = vị_trí_danh_định + delta_vị_trí
```

Phạm vi mặc định là **−0,02 đến +0,02 m trên mỗi trục**, tức ±2 cm theo mỗi tọa độ. Điểm danh định hiện tại là `[0.05, 0, -0.05] m` theo hệ tọa độ V4; đây là giá trị cấu hình cần được đối chiếu với thông tin gá lắp thực tế.

Vị trí mới giữ cố định suốt mẫu và hướng lắp giữ nguyên. Gia tốc tại điểm mới phải được tính lại từ chuyển động tịnh tiến, gia tốc góc và thành phần hướng tâm. Dịch vị trí không được thực hiện bằng cách cộng độ dài trực tiếp vào kênh gia tốc.

Trên cùng một vật rắn, dịch vị trí mà giữ nguyên hướng trục cảm biến không làm đổi gyro lý tưởng. Gyro đo trong mẫu kết hợp vẫn có thể đổi do delta bias của nó.

### 6.3. Tổ chức bộ dữ liệu tăng cường

Sinh ba loại biến thể: chỉ bias, chỉ vị trí, và kết hợp bias/vị trí. Mặc định tạo **100 mẫu trên mỗi BUILD, tổng 700 mẫu**, có thể điều chỉnh số lượng bằng cấu hình.

- Chỉ 7 BUILD được dùng làm nguồn tăng cường; 3 TEST giữ nguyên dữ liệu thật và không được dùng làm mẫu cha.
- Giữ quỹ đạo, tư thế, cửa sổ thời gian và nhãn ngã/không ngã của mẫu nguồn.
- Lưu `parent_id`/`group_id`, seed, bias gốc/mới, delta bias, vị trí gốc/mới, delta vị trí, hướng lắp và tham chiếu đến chuyển động nguồn.
- Ghi rõ mẫu nào thực sự thay đổi tín hiệu. Dịch vị trí trong một chuyển động không quay có thể không tạo thêm biến thiên IMU.
- Giữ các biến thể cùng bản ghi gốc trong cùng nhóm khi phân chia dữ liệu cho việc học máy về sau.

700 mẫu tăng cường vẫn chỉ có **7 bản ghi nguồn độc lập**. Tăng số mẫu không tự chứng minh khả năng nhận biết ngã được cải thiện.

## 7. Sản phẩm đầu ra

### Với từng file BUILD/TEST được chạy

- Mô hình quỹ đạo và tư thế đã tái dựng, cùng trạng thái chuyển động theo thời gian.
- CSV IMU thật, IMU lý tưởng và IMU ảo có bias, thống nhất thời gian và đơn vị.
- Đồ thị so sánh đầy đủ sáu trục.
- RMSE, MAE, tương quan và kết quả kiểm tra từng trục.
- Video 3D dựng từ cùng chuyển động dùng để tính IMU, thể hiện vị trí IMU.
- Thông tin cấu hình, cửa sổ sự kiện và nguyên nhân chưa đạt nếu có.

### Với bộ tăng cường

- CSV IMU mới và metadata của từng mẫu.
- Danh sách tổng hợp mẫu, nhãn, loại biến thể và bản ghi nguồn.
- Thông tin đủ để tái lập mẫu và truy ngược về chuyển động đã tái dựng.
- Video cho các mẫu đại diện hoặc khả năng xuất lại video tại vị trí IMU mới.

Toàn bộ chương trình triển khai bằng **MATLAB R2023a với Optimization Toolbox**, có lệnh chạy rõ ràng, lưu kết quả/checkpoint, báo cáo tổng hợp và ZIP kết quả để đánh giá.

## 8. Nguyên tắc triển khai và báo cáo kết quả

Người dùng chạy tái dựng trên dữ liệu thật và gửi kết quả. Trợ lý phân tích kết quả, sửa mã và kiểm tra công thức/cú pháp/dữ liệu tổng hợp; không tự chạy nhận dạng lại dữ liệu thật khi chưa được yêu cầu.

Mọi kết quả phải phân biệt rõ: kiểm tra tổng hợp, kết quả BUILD, kết quả TEST và kết quả tăng cường. File chưa chạy được ghi là chưa đánh giá; mô hình chưa đạt không được ghi thành đạt bằng cách nới ngưỡng hoặc loại mẫu khó sau khi xem kết quả.

Mức độ bám sáu trục là bằng chứng về tái dựng tín hiệu. Khi chưa có quỹ đạo, vận tốc, tư thế hoặc phép đo đối chiếu độc lập phù hợp, phải giữ giới hạn kết luận về độ đúng của chuyển động 3D. Các tham số khối lượng, quán tính, ma sát, lực tiếp xúc và lực va chạm không được xem là đã nhận dạng trong hướng tái dựng động học này.

Lợi ích của dữ liệu tăng cường đối với nhận biết ngã cần một thí nghiệm riêng: so sánh bộ nhận diện học từ dữ liệu thật với bộ học thêm tăng cường trên cùng dữ liệu kiểm tra thật, theo bản ghi gốc. Bài kiểm tra tái dựng hiện tại chưa thay thế thí nghiệm đó.

## 9. Điều kiện hoàn thành mục tiêu hiện tại

Mục tiêu giai đoạn này được coi là hoàn thành khi:

1. Cả 7 BUILD đạt bộ tiêu chí tái dựng đã chốt trên tất cả sáu trục.
2. Cả 3 TEST đạt cùng bộ tiêu chí với cấu hình chung cố định và phạm vi kiểm tra được khai báo đúng.
3. Tín hiệu IMU, trạng thái 3D, video và báo cáo nhất quán, kiểm tra lại và tái lập được.
4. Sinh được bộ biến thể bias/vị trí IMU trong các khoảng đã khai báo từ 7 BUILD, với nhãn và nguồn gốc đầy đủ.
5. Báo cáo đúng những gì đã chứng minh: độ bám tín hiệu tái dựng và khả năng sinh biến thể cảm biến của các sự kiện nguồn, cùng các giới hạn còn lại về chuyển động 3D và hiệu quả nhận biết ngã.
