CREATE TABLE Vulnerabilities (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Description NVARCHAR(255),
    Severity NVARCHAR(10),
    DetectedAt DATETIME
);

SELECT * FROM Vulnerabilities;

INSERT INTO Vulnerabilities (Description, Severity, DetectedAt)
VALUES 
('SQL Injection Vulnerability', 'HIGH', GETDATE()),
('Cross-Site Scripting (XSS)', 'MEDIUM', GETDATE() - 1),
('Privilege Escalation', 'CRITICAL', GETDATE() - 3),
('Insecure Deserialization', 'HIGH', GETDATE() - 5),
('Information Disclosure', 'LOW', GETDATE() - 7);


SELECT * FROM Vulnerabilities;

SELECT * 
FROM Vulnerabilities
WHERE Severity = 'HIGH'
ORDER BY DetectedAt DESC;

SELECT Severity, COUNT(*) AS Total
FROM Vulnerabilities
GROUP BY Severity
ORDER BY Total DESC;

SELECT * 
FROM Vulnerabilities
WHERE DetectedAt >= DATEADD(DAY, -7, GETDATE())
ORDER BY DetectedAt DESC;

SELECT TOP 1 *
FROM Vulnerabilities
WHERE Severity = 'CRITICAL'
ORDER BY DetectedAt DESC;
