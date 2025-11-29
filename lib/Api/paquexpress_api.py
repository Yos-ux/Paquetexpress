from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, DECIMAL, Text
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from datetime import datetime
import hashlib
import secrets
import mysql.connector
from sqlalchemy import text
from sqlalchemy.dialects.mysql import LONGTEXT


# Configuración de base de datos
DATABASE_URL = "mysql+mysqlconnector://root:202518@localhost/paquexpress_db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

app = FastAPI(title="API Paquexpress", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class Agente(Base):
    __tablename__ = "agentes"
    
    id_agente = Column(Integer, primary_key=True, index=True, autoincrement=True)
    codigo_empleado = Column(String(20), unique=True, nullable=False)
    nombre_completo = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    telefono = Column(String(20))
    vehiculo = Column(String(100))
    estado = Column(String(10), default="activo") 
    fecha_creacion = Column(DateTime, default=datetime.utcnow)

class Paquete(Base):
    __tablename__ = "paquetes"
    
    id_paquete = Column(Integer, primary_key=True, index=True, autoincrement=True)
    codigo_seguimiento = Column(String(50), unique=True, nullable=False)
    direccion_destino = Column(Text, nullable=False)
    destinatario = Column(String(255), nullable=False)
    telefono_destinatario = Column(String(20))
    instrucciones_entrega = Column(Text)
    peso_kg = Column(DECIMAL(5, 2))
    estado = Column(String(15), default="pendiente")  
    agente_asignado = Column(Integer, ForeignKey("agentes.id_agente"))
    fecha_creacion = Column(DateTime, default=datetime.utcnow)
    fecha_asignacion = Column(DateTime)
    fecha_entrega = Column(DateTime)
    latitud_entrega = Column(DECIMAL(10, 8))
    longitud_entrega = Column(DECIMAL(11, 8))
    foto_evidencia = Column(LONGTEXT)
    observaciones = Column(Text)

class HistorialEstado(Base):
    __tablename__ = "historial_estados"
    
    id_historial = Column(Integer, primary_key=True, index=True, autoincrement=True)
    id_paquete = Column(Integer, ForeignKey("paquetes.id_paquete"), nullable=False)
    estado_anterior = Column(String(15))
    estado_nuevo = Column(String(15), nullable=False)
    fecha_cambio = Column(DateTime, default=datetime.utcnow)
    observaciones = Column(Text)

# Función para verificar y crear la base de datos si no existe
def setup_database():
    try:
        # Primero conectar sin especificar base de datos
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='202518'
        )
        
        cursor = conn.cursor()
        
        # Verificar si la base de datos existe
        cursor.execute("SHOW DATABASES LIKE 'paquexpress_db'")
        result = cursor.fetchone()
        
        if not result:
            print("Creando base de datos 'paquexpress_db'...")
            cursor.execute("CREATE DATABASE paquexpress_db")
            print(" Base de datos creada exitosamente")
        else:
            print(" Base de datos 'paquexpress_db' ya existe")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"Error en setup_database: {e}")
        return False

# Llamar la función antes de crear el engine
print("Verificando base de datos...")
if setup_database():
    print("Conectando a la base de datos...")
    
    # Probar la conexión
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT DATABASE()"))
            current_db = result.scalar()
            print(f"Conectado a la base de datos: {current_db}")
            
            # Crear tablas
            Base.metadata.create_all(bind=engine)
            print(" Tablas creadas exitosamente")
            
    except Exception as e:
        print(f" Error de conexión: {e}")
        exit(1)
else:
    print(" No se pudo configurar la base de datos")
    exit(1)

# Dependencia de base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Modelos Pydantic
class AgenteBase(BaseModel):
    codigo_empleado: str = Field(..., min_length=3, max_length=20)
    nombre_completo: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    telefono: Optional[str] = Field(None, max_length=20)
    vehiculo: Optional[str] = Field(None, max_length=100)

class AgenteCreate(AgenteBase):
    password: str = Field(..., min_length=6)

class AgenteOut(AgenteBase):
    id_agente: int
    estado: str
    fecha_creacion: datetime
    
    class Config:
        from_attributes = True

class AgenteLogin(BaseModel):
    email: EmailStr
    password: str

class PaqueteBase(BaseModel):
    codigo_seguimiento: str = Field(..., min_length=3, max_length=50)
    direccion_destino: str = Field(..., min_length=5)
    destinatario: str = Field(..., min_length=2, max_length=255)
    telefono_destinatario: Optional[str] = Field(None, max_length=20)
    instrucciones_entrega: Optional[str] = None
    peso_kg: Optional[float] = Field(None, ge=0)

class PaqueteCreate(PaqueteBase):
    agente_asignado: Optional[int] = Field(None, ge=1)

class PaqueteOut(PaqueteBase):
    id_paquete: int
    estado: str
    agente_asignado: Optional[int]
    fecha_creacion: datetime
    fecha_asignacion: Optional[datetime] = None
    fecha_entrega: Optional[datetime] = None
    latitud_entrega: Optional[float] = None
    longitud_entrega: Optional[float] = None
    foto_evidencia: Optional[str] = None
    observaciones: Optional[str] = None
    
    class Config:
        from_attributes = True

class EntregaRequest(BaseModel):
    id_paquete: int = Field(..., ge=1)
    latitud: float = Field(..., ge=-90, le=90)
    longitud: float = Field(..., ge=-180, le=180)
    foto_evidencia: Optional[str] = None
    observaciones: Optional[str] = None

class LoginResponse(BaseModel):
    success: bool
    message: str
    agente: Optional[AgenteOut] = None
    token: Optional[str] = None

class BasicResponse(BaseModel):
    success: bool
    message: str

# Funciones de seguridad
def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    return f"{salt}${hashlib.sha256((salt + password).encode()).hexdigest()}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        salt, stored_hash = hashed_password.split('$')
        new_hash = hashlib.sha256((salt + plain_password).encode()).hexdigest()
        return new_hash == stored_hash
    except:
        return False

# ENDPOINTS
@app.get("/")
def root():
    return {"message": "API Paquexpress funcionando correctamente", "version": "1.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow()}

@app.post("/auth/registrar", response_model=AgenteOut)
def registrar_agente(agente: AgenteCreate, db: Session = Depends(get_db)):
    # Verificar si el email ya existe
    existente = db.query(Agente).filter(Agente.email == agente.email).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El email ya está registrado"
        )
    
    # Verificar si el código de empleado ya existe
    existente_codigo = db.query(Agente).filter(Agente.codigo_empleado == agente.codigo_empleado).first()
    if existente_codigo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El código de empleado ya existe"
        )
    
    # Crear nuevo agente
    hashed_password = hash_password(agente.password)
    nuevo_agente = Agente(
        codigo_empleado=agente.codigo_empleado,
        nombre_completo=agente.nombre_completo,
        email=agente.email,
        password_hash=hashed_password,
        telefono=agente.telefono,
        vehiculo=agente.vehiculo,
        estado="activo"
    )
    
    db.add(nuevo_agente)
    db.commit()
    db.refresh(nuevo_agente)
    return nuevo_agente

@app.post("/auth/login", response_model=LoginResponse)
def login(credenciales: AgenteLogin, db: Session = Depends(get_db)):
    agente = db.query(Agente).filter(Agente.email == credenciales.email).first()
    
    if not agente or not verify_password(credenciales.password, agente.password_hash):
        return LoginResponse(
            success=False,
            message="Credenciales inválidas"
        )
    
    if agente.estado != "activo":
        return LoginResponse(
            success=False,
            message="Agente inactivo. Contacte al administrador."
        )
    
    token_simulado = f"token_{agente.id_agente}_{datetime.utcnow().timestamp()}"
    
    return LoginResponse(
        success=True,
        message="Login exitoso",
        agente=agente,
        token=token_simulado
    )

@app.post("/paquetes/crear", response_model=PaqueteOut)
def crear_paquete(paquete: PaqueteCreate, db: Session = Depends(get_db)):
    # Verificar si el código de seguimiento ya existe
    existente = db.query(Paquete).filter(Paquete.codigo_seguimiento == paquete.codigo_seguimiento).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El código de seguimiento ya existe"
        )
    
    # Verificar agente si está asignado
    if paquete.agente_asignado:
        agente = db.query(Agente).filter(Agente.id_agente == paquete.agente_asignado).first()
        if not agente:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El agente asignado no existe"
            )
    
    # Crear nuevo paquete
    nuevo_paquete = Paquete(
        codigo_seguimiento=paquete.codigo_seguimiento,
        direccion_destino=paquete.direccion_destino,
        destinatario=paquete.destinatario,
        telefono_destinatario=paquete.telefono_destinatario,
        instrucciones_entrega=paquete.instrucciones_entrega,
        peso_kg=paquete.peso_kg,
        estado="pendiente",
        agente_asignado=paquete.agente_asignado
    )
    
    if paquete.agente_asignado:
        nuevo_paquete.estado = "asignado"
        nuevo_paquete.fecha_asignacion = datetime.utcnow()
    
    db.add(nuevo_paquete)
    db.commit()
    db.refresh(nuevo_paquete)
    
    # Crear registro en historial
    historial = HistorialEstado(
        id_paquete=nuevo_paquete.id_paquete,
        estado_nuevo=nuevo_paquete.estado,
        observaciones="Paquete creado"
    )
    db.add(historial)
    db.commit()
    
    return nuevo_paquete

@app.get("/paquetes/asignados/{agente_id}", response_model=List[PaqueteOut])
def obtener_paquetes_asignados(agente_id: int, db: Session = Depends(get_db)):
    # Verificar que el agente existe
    agente = db.query(Agente).filter(Agente.id_agente == agente_id).first()
    if not agente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Agente no encontrado"
        )
    
    # Obtener paquetes asignados
    paquetes = db.query(Paquete).filter(
        Paquete.agente_asignado == agente_id,
        Paquete.estado.in_(['asignado', 'en_camino'])
    ).all()
    
    return paquetes

@app.get("/paquetes/{paquete_id}", response_model=PaqueteOut)
def obtener_paquete(paquete_id: int, db: Session = Depends(get_db)):
    paquete = db.query(Paquete).filter(Paquete.id_paquete == paquete_id).first()
    if not paquete:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paquete no encontrado"
        )
    return paquete

@app.post("/entregas/registrar", response_model=BasicResponse)
def registrar_entrega(entrega: EntregaRequest, db: Session = Depends(get_db)):
    # Verificar que el paquete existe
    paquete = db.query(Paquete).filter(Paquete.id_paquete == entrega.id_paquete).first()
    if not paquete:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paquete no encontrado"
        )
    
    # Verificar que el paquete puede ser entregado
    if paquete.estado not in ['asignado', 'en_camino']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El paquete no está asignado para entrega"
        )
    
    # Crear registro en historial
    historial = HistorialEstado(
        id_paquete=paquete.id_paquete,
        estado_anterior=paquete.estado,
        estado_nuevo='entregado',
        observaciones=entrega.observaciones
    )
    
    # Actualizar paquete
    paquete.estado = 'entregado'
    paquete.fecha_entrega = datetime.utcnow()
    paquete.latitud_entrega = entrega.latitud
    paquete.longitud_entrega = entrega.longitud
    paquete.foto_evidencia = entrega.foto_evidencia
    paquete.observaciones = entrega.observaciones
    
    db.add(historial)
    db.commit()
    
    return BasicResponse(
        success=True,
        message="Entrega registrada exitosamente"
    )

@app.put("/paquetes/{paquete_id}/estado")
def actualizar_estado_paquete(paquete_id: int, nuevo_estado: str, db: Session = Depends(get_db)):
    estados_permitidos = ['pendiente', 'asignado', 'en_camino', 'entregado', 'cancelado']
    
    if nuevo_estado not in estados_permitidos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Estado no válido. Estados permitidos: {estados_permitidos}"
        )
    
    paquete = db.query(Paquete).filter(Paquete.id_paquete == paquete_id).first()
    if not paquete:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paquete no encontrado"
        )
    
    # Crear registro en historial
    historial = HistorialEstado(
        id_paquete=paquete.id_paquete,
        estado_anterior=paquete.estado,
        estado_nuevo=nuevo_estado,
        observaciones=f"Estado cambiado manualmente"
    )
    
    paquete.estado = nuevo_estado
    if nuevo_estado == 'asignado':
        paquete.fecha_asignacion = datetime.utcnow()
    elif nuevo_estado == 'entregado':
        paquete.fecha_entrega = datetime.utcnow()
    
    db.add(historial)
    db.commit()
    
    return BasicResponse(
        success=True,
        message=f"Estado del paquete actualizado a '{nuevo_estado}'"
    )

@app.post("/poblar-datos-prueba")
def poblar_datos_prueba(db: Session = Depends(get_db)):
    try:
        # Crear agentes de prueba
        agentes_prueba = [
            Agente(
                codigo_empleado="AGE001",
                nombre_completo="Carlos Rodríguez Méndez",
                email="carlos@paquexpress.com",
                password_hash=hash_password("password123"),
                telefono="4421112233",
                vehiculo="Moto Honda CB190",
                estado="activo"
            ),
            Agente(
                codigo_empleado="AGE002", 
                nombre_completo="Ana Martínez López",
                email="ana@paquexpress.com",
                password_hash=hash_password("password456"),
                telefono="4424445566", 
                vehiculo="Auto Nissan Versa",
                estado="activo"
            )
        ]
        
        for agente in agentes_prueba:
            # Verificar si ya existe
            existente = db.query(Agente).filter(Agente.email == agente.email).first()
            if not existente:
                db.add(agente)
        
        db.commit()
        
        # Crear paquetes de prueba
        paquetes_prueba = [
            Paquete(
                codigo_seguimiento="PKG2024001",
                direccion_destino="Av. Pie de la Cuesta 2501, Col. Unidad Nacional, Querétaro",
                destinatario="Juan Pérez López",
                telefono_destinatario="4421234567",
                instrucciones_entrega="Entregar en recepción, pedir identificación",
                peso_kg=2.5,
                estado="asignado",
                agente_asignado=1,
                fecha_asignacion=datetime.utcnow()
            ),
            Paquete(
                codigo_seguimiento="PKG2024002",
                direccion_destino="Blvd. Bernardo Quintana 5000, Col. Centro Sur, Querétaro",
                destinatario="María García Hernández",
                telefono_destinatario="4427654321",
                instrucciones_entrega="Dejar con vecino si no hay quien reciba",
                peso_kg=1.8,
                estado="pendiente"
            )
        ]
        
        for paquete in paquetes_prueba:
            # Verificar si ya existe
            existente = db.query(Paquete).filter(Paquete.codigo_seguimiento == paquete.codigo_seguimiento).first()
            if not existente:
                db.add(paquete)
        
        db.commit()
        
        return BasicResponse(
            success=True,
            message="Datos de prueba creados exitosamente"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear datos de prueba: {str(e)}"
        )

@app.get("/agentes", response_model=List[AgenteOut])
def listar_agentes(db: Session = Depends(get_db)):
    agentes = db.query(Agente).filter(Agente.estado == "activo").all()
    return agentes

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)