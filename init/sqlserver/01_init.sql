-- รันครั้งแรกเพื่อสร้าง database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'facerecog')
BEGIN
    CREATE DATABASE facerecog;
END
GO
