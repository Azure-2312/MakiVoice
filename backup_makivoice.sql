-- ============================================================================
-- PROYECTO: MAKI VOICE (LSP TRANSLATOR)
-- RESPALDO DE BASE DE DATOS - POSTGRESQL (v15+)
-- GENERO: Esquemas Normalizado y NoSQL-Equivalent (JSONB / Arrays)
-- ============================================================================

CREATE DATABASE makivoice_db;
\c makivoice_db;

-- ============================================================================
-- APROXIMACIÓN 1: ESQUEMA TOTALMENTE NORMALIZADO (RECOMENDADO PARA PRODUCCIÓN)
-- ============================================================================

-- 1. Tabla de Perfiles de Usuario
CREATE TABLE user_profiles (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    learning_level INTEGER DEFAULT 1 CHECK (learning_level BETWEEN 1 AND 9),
    quiz_streak INTEGER DEFAULT 0 CHECK (quiz_streak >= 0),
    last_quiz_date DATE,
    umbral_inclinacion DOUBLE PRECISION DEFAULT 2.0,
    umbral_movimiento_gyro DOUBLE PRECISION DEFAULT 1.2,
    umbral_movimiento_accel DOUBLE PRECISION DEFAULT 2.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Calibración Analógica de los Dedos
CREATE TABLE calibration_data (
    profile_id VARCHAR(100) REFERENCES user_profiles(id) ON DELETE CASCADE,
    finger_index INTEGER NOT NULL CHECK (finger_index BETWEEN 0 AND 4), -- 0=Thumb, 1=Index, 2=Middle, 3=Ring, 4=Pinky
    flex_min INTEGER NOT NULL DEFAULT 1200 CHECK (flex_min >= 0 AND flex_min <= 4095),
    flex_mid INTEGER NOT NULL DEFAULT 2600 CHECK (flex_mid >= 0 AND flex_mid <= 4095),
    flex_max INTEGER NOT NULL DEFAULT 4000 CHECK (flex_max >= 0 AND flex_max <= 4095),
    PRIMARY KEY (profile_id, finger_index)
);

-- 3. Tabla de Palabras Frecuentemente Utilizadas
CREATE TABLE frequent_words (
    id SERIAL PRIMARY KEY,
    profile_id VARCHAR(100) REFERENCES user_profiles(id) ON DELETE CASCADE,
    word VARCHAR(100) NOT NULL,
    use_count INTEGER DEFAULT 1 CHECK (use_count >= 1),
    UNIQUE (profile_id, word)
);

-- 4. Tabla de Señas/Gestos Personalizados (Grabados por el usuario)
CREATE TABLE custom_signs (
    id SERIAL PRIMARY KEY,
    profile_id VARCHAR(100) REFERENCES user_profiles(id) ON DELETE CASCADE,
    word VARCHAR(100) NOT NULL,
    flex_pattern VARCHAR(5) NOT NULL CHECK (flex_pattern ~ '^[01]{5}$'), -- Representación binaria ej. '01011'
    is_dynamic BOOLEAN DEFAULT FALSE,
    contacts_json JSONB, -- Historial de contactos o aceleraciones
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (profile_id, word)
);

-- 5. Tabla de Historial de Cuestionarios (Quizzes)
CREATE TABLE quiz_history (
    id SERIAL PRIMARY KEY,
    profile_id VARCHAR(100) REFERENCES user_profiles(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 5),
    total_questions INTEGER DEFAULT 5,
    resolved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Tabla de Historial de Exámenes
CREATE TABLE exam_history (
    id SERIAL PRIMARY KEY,
    profile_id VARCHAR(100) REFERENCES user_profiles(id) ON DELETE CASCADE,
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 9),
    passed BOOLEAN DEFAULT FALSE,
    score INTEGER NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices optimizados para búsquedas
CREATE INDEX idx_user_profiles_name ON user_profiles(name);
CREATE INDEX idx_custom_signs_word ON custom_signs(profile_id, word);
CREATE INDEX idx_quiz_history_profile ON quiz_history(profile_id);

-- ============================================================================
-- APROXIMACIÓN 2: TABLA ÚNICA EQUIVALENTE A HIVE (JSONB + ARRAYS)
-- Esta tabla representa 1-a-1 el objeto local de Hive almacenado en la App de Flutter.
-- ============================================================================

CREATE TABLE hive_profiles_backup (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    flex_min INTEGER[] DEFAULT '{1200,1200,1200,1200,1200}',
    flex_mid INTEGER[] DEFAULT '{2600,2600,2600,2600,2600}',
    flex_max INTEGER[] DEFAULT '{4000,4000,4000,4000,4000}',
    frequent_words TEXT[] DEFAULT '{}',
    custom_signs JSONB DEFAULT '{}'::jsonb,
    quiz_history JSONB DEFAULT '[]'::jsonb,
    exam_history JSONB DEFAULT '[]'::jsonb,
    learning_level INTEGER DEFAULT 1,
    quiz_streak INTEGER DEFAULT 0,
    last_quiz_date DATE,
    umbral_inclinacion DOUBLE PRECISION DEFAULT 2.0,
    umbral_movimiento_gyro DOUBLE PRECISION DEFAULT 1.2,
    umbral_movimiento_accel DOUBLE PRECISION DEFAULT 2.5,
    backed_up_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CARGA DE DATOS DE PRUEBA (SEEDS / DUMMY DATA)
-- Inserta la cuenta de prueba oficial "TEST" con clave "123" y nivel 9
-- ============================================================================

-- 1. Insertar perfil en esquema normalizado
INSERT INTO user_profiles 
(id, name, password, learning_level, quiz_streak, last_quiz_date, umbral_inclinacion, umbral_movimiento_gyro, umbral_movimiento_accel)
VALUES 
('test_profile_uuid', 'TEST', '123', 9, 3, '2026-07-16', 2.0, 1.2, 2.5);

-- 2. Insertar valores analógicos de flexión calibrados (Divisor de tensión inverso)
INSERT INTO calibration_data (profile_id, finger_index, flex_min, flex_mid, flex_max) VALUES
('test_profile_uuid', 0, 1200, 2600, 4000), -- Pulgar
('test_profile_uuid', 1, 1200, 2600, 4000), -- Índice
('test_profile_uuid', 2, 1200, 2600, 4000), -- Medio
('test_profile_uuid', 3, 1200, 2600, 4000), -- Anular
('test_profile_uuid', 4, 1200, 2600, 4000); -- Meñique

-- 3. Insertar palabras frecuentes iniciales
INSERT INTO frequent_words (profile_id, word, use_count) VALUES
('test_profile_uuid', 'HOLA', 12),
('test_profile_uuid', 'GRACIAS', 8),
('test_profile_uuid', 'AYUDA', 5),
('test_profile_uuid', 'UNFV', 2);

-- 4. Insertar seña personalizada (espacio)
INSERT INTO custom_signs (profile_id, word, flex_pattern, is_dynamic, contacts_json) VALUES
('test_profile_uuid', 'ESPACIO', '01011', FALSE, '{}'::jsonb);

-- 5. Insertar backup en la tabla equivalente Hive (NoSQL replication)
INSERT INTO hive_profiles_backup 
(id, name, password, flex_min, flex_mid, flex_max, frequent_words, custom_signs, quiz_history, exam_history, learning_level, quiz_streak, last_quiz_date)
VALUES (
    'test_profile_uuid', 
    'TEST', 
    '123', 
    '{1200,1200,1200,1200,1200}', 
    '{2600,2600,2600,2600,2600}', 
    '{4000,4000,4000,4000,4000}', 
    '{"HOLA", "GRACIAS", "BIEN", "NECESITO", "AYUDA"}', 
    '{"ESPACIO": "01011"}'::jsonb, 
    '[{"date": "2026-07-16", "score": 5, "total": 5}]'::jsonb, 
    '[{"date": "2026-07-16", "level": 1, "passed": true, "score": 5}]'::jsonb, 
    9, 
    3, 
    '2026-07-16'
);
