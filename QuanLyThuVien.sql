﻿USE MASTER
CREATE DATABASE QuanLyThuVien
USE QuanLyThuVien

CREATE TABLE SACH
(
	IDSach varchar(5) PRIMARY KEY,
	TenSach nvarchar(200) NOT NULL,
	TheLoai nvarchar(50) NOT NULL,
	TacGia nvarchar(100) NOT NULL,
	NamXB int NOT NULL,
	NhaXB nvarchar(20) NOT NULL,
	NgNhap datetime NOT NULL,
	TriGia money NOT NULL,
	TinhTrang nvarchar(20)	
)
DROP TABLE SACH

CREATE TABLE THEDOCGIA
(
	IDDocGia int PRIMARY KEY,
	HoTenDG nvarchar(50) NOT NULL,
	NgSinhDG datetime NOT NULL,
	DiaChiDG nvarchar(50) NOT NULL,
	EmailDG varchar(30) NOT NULL,
	LoaiDG nvarchar(50) NOT NULL,
	NgLapThe datetime NOT NULL,
	NgHetHan datetime,
	TongNo money DEFAULT(0)
)
DROP TABLE THEDOCGIA

CREATE TABLE PHIEUMUON
(
	IDPhieuMuon varchar(5) PRIMARY KEY NOT NULL,
	IDSach varchar(5) FOREIGN KEY REFERENCES SACH(IDSach),
	IDDocGia int FOREIGN KEY REFERENCES THEDOCGIA(IDDocGia),
	NgayMuon datetime NOT NULL,
	HanTra datetime NOT NULL
)
DROP TABLE PHIEUMUON

CREATE TABLE PHIEUTRA
(
	IDPhieuMuon varchar(5) FOREIGN KEY REFERENCES PHIEUMUON(IDPhieuMuon),
	IDDocGia int FOREIGN KEY REFERENCES THEDOCGIA(IDDocGia),
	IDSach varchar(5) FOREIGN KEY REFERENCES SACH(IDSach),
	NgayTra datetime NOT NULL,
	CONSTRAINT PK_PT PRIMARY KEY (IDPhieuMuon, IDDocGia, IDSach)
)
DROP TABLE PHIEUTRA

CREATE TABLE PHIEUTIENPHAT
(
	IDTienPhat varchar(5) PRIMARY KEY NOT NULL,
	IDDocGia int FOREIGN KEY REFERENCES THEDOCGIA(IDDocGia),
	SoTienThu money,
	ConLai money
)
DROP TABLE PHIEUTIENPHAT

SET DATEFORMAT dmy

ALTER TABLE THEDOCGIA ADD CONSTRAINT CK_LDG CHECK (LoaiDG IN(N'Thường', 'VIP'))
ALTER TABLE THEDOCGIA ADD CONSTRAINT CK_T CHECK (DATEDIFF(year, NgSinhDG, NgLapThe) BETWEEN 18 AND 55)
ALTER TABLE THEDOCGIA DROP CK_LDG
ALTER TABLE THEDOCGIA DROP CK_T

ALTER TABLE SACH ADD CONSTRAINT CK_TL CHECK (TheLoai IN(N'Truyện', N'Văn học dân gian', N'Văn học quốc tế'))
ALTER TABLE SACH ADD CONSTRAINT CK_XB CHECK ((year(NgNhap) - NamXB) <= 8)
ALTER TABLE SACH DROP CK_TL
ALTER TABLE SACH DROP CK_XB

-- Max 100 tác giả
CREATE TRIGGER TRG_TG ON SACH
FOR INSERT, UPDATE
AS
BEGIN
	IF((SELECT COUNT(DISTINCT TacGia) FROM SACH) > 100)
	BEGIN
		PRINT N'Lỗi: Vượt quá 100 tác giả'
		ROLLBACK TRANSACTION
	END
END

DROP TRIGGER TRG_TG

-- Tuổi độc giả
CREATE TRIGGER TRG_T ON THEDOCGIA
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @NGSINHDG datetime, @NGLAPTHE datetime
	
	SELECT @NGSINHDG = NgSinhDG, @NGLAPTHE = NgLapThe
	FROM INSERTED

	IF(DATEDIFF(year, @NGSINHDG, @NGLAPTHE) < 18 OR DATEDIFF(year, @NGSINHDG,  @NGLAPTHE) > 55)
	BEGIN
		PRINT N'Lỗi: Tuổi của độc giả phải từ 18 đến 55'
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		PRINT N'Thành công'		
	END
END
			
DROP TRIGGER TRG_T								 

-- Ngày hết hạn
CREATE TRIGGER TRG_NHH ON THEDOCGIA
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @NGLAPTHE datetime
	
	SELECT @NGLAPTHE = NgLapThe
	FROM INSERTED
	
	UPDATE THEDOCGIA 
	SET NgHetHan = DATEADD(month, 6, @NGLAPTHE)
END

DROP TRIGGER TRG_NHH	

-- Mượn sách
CREATE TRIGGER TRG_MS ON PHIEUMUON
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @IDSACH varchar(5), @IDDOCGIA int, @NGAYMUON datetime, @TINHTRANG nvarchar(20), @NGHETHAN datetime
	
	SELECT @IDSACH = IDSach, @IDDOCGIA = IDDocGia, @NGAYMUON = NgayMuon
	FROM INSERTED
	SELECT @TINHTRANG = TinhTrang
	FROM SACH
	WHERE @IDSACH = IDSach
	SELECT @NGHETHAN = NgHetHan
	FROM THEDOCGIA
	WHERE @IDDOCGIA = IDDocGia

	IF((@TINHTRANG = N'Cho mượn') OR (@NGHETHAN <= @NGAYMUON) OR EXISTS (SELECT * FROM PHIEUMUON WHERE HanTra < @NGAYMUON))
	BEGIN
		PRINT N'Lỗi: Chỉ cho mượn với thẻ còn hạn, không có sách mượn quá hạn, và sách không có người đang mượn'
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		PRINT N'Thành công'
	END
END

DROP TRIGGER TRG_MS

-- Max Mượn
CREATE TRIGGER TRG_MM ON PHIEUMUON
FOR INSERT
AS
BEGIN
	DECLARE @IDDOCGIA int

	SELECT @IDDOCGIA = IDDocGia
	FROM INSERTED

	IF((SELECT COUNT(DISTINCT IDSach) FROM PHIEUMUON WHERE @IDDOCGIA = IDDocGia) > 5)
	BEGIN
		PRINT N'Lỗi: Mỗi độc giả mượn tối đa 5 quyển sách'
		ROLLBACK TRANSACTION 
	END
	ELSE
	BEGIN
		PRINT N'Thành công'
	END
END

DROP TRIGGER TRG_MM

-- Hạn trả
CREATE TRIGGER TRG_HT ON PHIEUMUON
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @NGAYMUON datetime
	
	SELECT @NGAYMUON = NgayMuon
	FROM INSERTED
	
	UPDATE PHIEUMUON
	SET HanTra = DATEADD(day, 4, @NGAYMUON)
END

DROP TRIGGER TRG_HT
