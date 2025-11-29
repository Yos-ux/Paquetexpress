
DROP DATABASE IF EXISTS paquexpress_db;
CREATE DATABASE paquexpress_db;
USE paquexpress_db;

CREATE TABLE `agentes` (
  `id_agente` int NOT NULL AUTO_INCREMENT,
  `codigo_empleado` varchar(20) NOT NULL,
  `nombre_completo` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `vehiculo` varchar(100) DEFAULT NULL,
  `estado` enum('activo','inactivo') DEFAULT 'activo',
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_agente`),
  UNIQUE KEY `codigo_empleado` (`codigo_empleado`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla paquetes
CREATE TABLE `paquetes` (
  `id_paquete` int NOT NULL AUTO_INCREMENT,
  `codigo_seguimiento` varchar(50) NOT NULL,
  `direccion_destino` text NOT NULL,
  `destinatario` varchar(255) NOT NULL,
  `telefono_destinatario` varchar(20) DEFAULT NULL,
  `instrucciones_entrega` text,
  `peso_kg` decimal(5,2) DEFAULT NULL,
  `estado` enum('pendiente','asignado','en_camino','entregado','fallido') DEFAULT 'pendiente',
  `agente_asignado` int DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `fecha_asignacion` datetime DEFAULT NULL,
  `fecha_entrega` datetime DEFAULT NULL,
  `latitud_entrega` decimal(10,8) DEFAULT NULL,
  `longitud_entrega` decimal(11,8) DEFAULT NULL,
  `foto_evidencia` longtext,
  `observaciones` text,
  PRIMARY KEY (`id_paquete`),
  UNIQUE KEY `codigo_seguimiento` (`codigo_seguimiento`),
  KEY `agente_asignado` (`agente_asignado`),
  CONSTRAINT `paquetes_ibfk_1` FOREIGN KEY (`agente_asignado`) REFERENCES `agentes` (`id_agente`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insertar datos de agentes
INSERT INTO `agentes` (`id_agente`, `codigo_empleado`, `nombre_completo`, `email`, `password_hash`, `telefono`, `vehiculo`, `estado`, `fecha_creacion`) VALUES
(1, 'AGE001', 'Carlos Rodríguez', 'carlos@paquexpress.com', 'hashed_password_123', '4421112233', 'Moto Honda CB190', 'activo', '2025-11-28 20:45:37'),
(2, 'AGE002', 'Ana Martínez', 'ana@paquexpress.com', 'hashed_password_456', '4424445566', 'Auto Nissan Versa', 'activo', '2025-11-28 20:45:37'),
(3, 'AGE003', 'Luis García Pérez', 'luis@paquexpress.com', '9a775e0e0811213f678e6c0d52d58368$0bf0d37d7713a144313c870ffb242199639250511f38c14fc6b3eeac8101181a', '4427778899', 'Moto Yamaha MT-09', 'activo', '2025-11-29 03:01:57'),
(4, 'TEST001', 'Agente Test', 'test@paquexpress.com', '7eca487c71a55ba3f4cef5df72f2d263$c77e2dc1f98e50199628f6739193699aa860d6c7ae4fb2ff5b6e8a2b0393ea4b', '4420000000', 'Moto Test', 'activo', '2025-11-29 03:14:29'),
(5, 'XIM25', 'Yoselin', 'yos@paquexpress.com', '5b3a92f8ab9cdad1d7a40c1e03dd72af$6345d20636b929792f8ee1a12f97bd53e9911ecee83d863ef5c1454c4d589f05', '4420000000', 'Moto Test', 'activo', '2025-11-29 03:17:02');


INSERT INTO `paquetes` (`codigo_seguimiento`, `direccion_destino`, `destinatario`, `telefono_destinatario`, `instrucciones_entrega`, `peso_kg`, `estado`, `agente_asignado`, `fecha_asignacion`) VALUES
('PKG2024001', 'Av. Pie de la Cuesta 2501, Querétaro', 'Juan Pérez López', '4421234567', 'Entregar en recepción', 2.50, 'asignado', 1, NOW()),
('PKG2024002', 'Calle Corregidora 123, Centro, Querétaro', 'María García Hernández', '4427654321', 'Dejar con vecino', 1.80, 'pendiente', NULL, NULL);

