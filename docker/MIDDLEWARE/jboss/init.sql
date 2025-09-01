-- 초기 데이터베이스 스키마 생성
CREATE SCHEMA IF NOT EXISTS app_schema;

-- 샘플 테이블 생성
CREATE TABLE IF NOT EXISTS app_schema.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_schema.roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(30) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS app_schema.user_roles (
    user_id INTEGER REFERENCES app_schema.users(id),
    role_id INTEGER REFERENCES app_schema.roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- 초기 데이터 삽입
INSERT INTO app_schema.roles (role_name, description) VALUES 
('ADMIN', '시스템 관리자'),
('USER', '일반 사용자'),
('MANAGER', '매니저')
ON CONFLICT (role_name) DO NOTHING;

INSERT INTO app_schema.users (username, email, password_hash) VALUES 
('admin', 'admin@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
('testuser', 'test@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy')
ON CONFLICT (username) DO NOTHING;

-- 사용자-역할 매핑
INSERT INTO app_schema.user_roles (user_id, role_id) 
SELECT u.id, r.id 
FROM app_schema.users u, app_schema.roles r 
WHERE u.username = 'admin' AND r.role_name = 'ADMIN'
ON CONFLICT DO NOTHING;

INSERT INTO app_schema.user_roles (user_id, role_id) 
SELECT u.id, r.id 
FROM app_schema.users u, app_schema.roles r 
WHERE u.username = 'testuser' AND r.role_name = 'USER'
ON CONFLICT DO NOTHING;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_users_email ON app_schema.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON app_schema.users(username);
