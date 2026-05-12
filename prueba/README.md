# Nombre del proyecto

## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays

## 2. Referencias
[0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3

## 3. Desarrollo

### 3.0 Descripción general del sistema
El sistema completo implementado en la FPGA tiene como objetivo capturar dos números enteros positivos de hasta tres dígitos decimales desde un teclado hexadecimal, realizar la suma aritmética sin signo de ambos valores y posteriormente desplegar los resultados en dispositivos de siete segmentos.

El diseño se estructura en tres subsistemas principales: lectura del teclado, suma aritmética y despliegue en displays. Cada subsistema opera de forma sincrónica bajo un único reloj de 27 MHz, garantizando coherencia temporal en todo el sistema.

### 3.1 Subsistema 1 (Lectura de teclado)
#### 1. Encabezado del módulo
```SystemVerilog
module mi_modulo(
    input logic     entrada_i,      
    output logic    salida_i 
    );
```

### 3.2 Subsistema 2: Suma aritmética de los datos

#### 1. Encabezado del módulo
```SystemVerilog
module subsistema_suma(
    input  logic        clk,
    input  logic        rst,

    input  logic        datos_listos,
    input  logic [9:0]  num1_reg,
    input  logic [9:0]  num2_reg,

    output logic [10:0] suma,
    output logic        suma_ready
);
```


#### 2. Parámetros
Este módulo no utiliza parámetros configurables. El tamaño de los buses está definido para soportar números de hasta 10 bits (0–999 en uso funcional) y un resultado de 11 bits para contemplar posibles desbordamientos.

#### 3. Entradas y salidas:
- num1_reg: primer número capturado por el subsistema de lectura (hasta 10 bits).
- num2_reg: segundo número capturado por el subsistema de lectura (hasta 10 bits).
- datos_listos: señal de control que indica que ambos números están disponibles.
- suma: resultado de la operación aritmética sin signo entre los dos operandos.
- suma_ready: señal de salida que indica que el resultado de la suma está disponible para el siguiente subsistema.

#### 4. Criterios de diseño
El subsistema de suma aritmética es el encargado de realizar la operación de adición entre los dos números enteros positivos capturados por el subsistema de lectura del teclado hexadecimal. Este módulo recibe como entrada los registros num1_reg y num2_reg, los cuales contienen los valores decimales de hasta tres dígitos cada uno, previamente validados y almacenados en la FPGA.

La operación de suma se realiza de forma sincrónica utilizando lógica descrita en SystemVerilog, aprovechando las capacidades de operación aritmética del lenguaje. El resultado se almacena en una señal de 11 bits (suma) para garantizar la representación correcta del resultado, incluyendo posibles casos de desbordamiento dentro del rango permitido por el sistema.

El subsistema se activa mediante la señal datos_listos, la cual indica que ambos operandos han sido capturados correctamente. Una vez realizada la suma, se genera la señal suma_ready, que notifica al siguiente subsistema que el resultado está disponible para su despliegue en los dispositivos de siete segmentos.

Este diseño garantiza una operación completamente sincrónica con el reloj del sistema (27 MHz), manteniendo la coherencia temporal entre los subsistemas.

#### 5. Testbench
Para la validación del subsistema de suma se desarrolló un testbench en SystemVerilog que permite verificar el comportamiento funcional del módulo bajo distintos escenarios representativos.

Las pruebas realizadas incluyen:

- 123 + 456 = 579
- 9 + 5 = 14
- 999 + 1 = 1000
- 1023 + 1 = 1024 (caso de prueba de estrés en ancho de palabra)

Los resultados obtenidos en simulación demuestran que el módulo realiza correctamente la operación aritmética en todos los casos, generando la señal suma_ready de forma adecuada para la sincronización con el subsistema de despliegue.

## 4. Consumo de recursos

## 5. Problemas encontrados durante el proyecto
- Ajuste de anchos de bits para evitar overflow

## Apendices:
### Apendice 1:
texto, imágen, etc
