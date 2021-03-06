/*
* ARQUITECTURA DE COMPUTADORES
* 2� Grado en Ingenieria Informatica
*
* PRACTICA 2: "Suma De Matrices Paralela"
* >> Arreglar for en __global__
* >> Pasar numElem como argumento
*
* AUTOR: Ivanes
*/
///////////////////////////////////////////////////////////////////////////
// Includes
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda_runtime.h>
#include "device_launch_parameters.h"

// Defines
#define RAN_MIN 1
#define RAN_MAX 5

// Declaracion de funciones
void cudaDev()
{
	// Saca num hilos, funcion CUDA
	int dev = 0;
	cudaDeviceProp deviceProp;
	cudaGetDeviceProperties(&deviceProp, dev);

	//
	printf("\n***********************************************************************\n\n");
	printf("> Nombre Dispositivos: %s\n", deviceProp.name);
	printf("> Capacidad de Computo: %d.%d\n", deviceProp.major, deviceProp.minor);
	printf("> Numero de MultiProcesadores: %d \n", deviceProp.multiProcessorCount);
	printf("> Numero de Nucleos (Arq. PASCAL): %d \n", 64);
	printf("> Maximo de hilos por eje en bloque\n");
	printf(" \t[x -> %d]\n \t[y -> %d]\n \t[z -> %d]\n",deviceProp.maxThreadsDim[0], deviceProp.maxThreadsDim[1], deviceProp.maxThreadsDim[2]);
	printf("> Maximo de bloques por eje\n");
	printf(" \t[x -> %d]\n \t[y -> %d]\n \t[z -> %d]\n",deviceProp.maxGridSize[0], deviceProp.maxGridSize[1], deviceProp.maxGridSize[2]);
	printf("\n***********************************************************************\n");
}

__global__
void mueveFila(int *dev_matriz, int *dev_matriz_resultado, int numFilas)
{
	int columna = threadIdx.x;
	int fila = threadIdx.y;

	// Indice normal
	int myID = fila + columna * blockDim.x;

	// Indice sumandole una fila, y restandole una columna en la ultima fila
	if(fila == (numFilas-1))
		columna--;

	int myID_2 = (fila+1) + columna * blockDim.x;

	dev_matriz_resultado[myID_2] = dev_matriz[myID];
}

// MAIN: Rutina principal ejecutada en el host
int main(int argc, char** argv)
{
	//Eventos
	cudaEvent_t start;
	cudaEvent_t stop;

	// Creacion de eventos
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	// Marca de inicio
	cudaEventRecord(start, 0);

	// Declaracion
	int *hst_matriz;
	int *hst_matriz_resultado;
	int *dev_matriz;
	int *dev_matriz_resultado;

	// Filas y Columnas
	int filas;
	int columnas;

	// Llama a la funci�n Cuda que devuelve info
	cudaDev();

	// Pregunta n�mero de filas y columnas
	printf("Numero maximo de elementos: 1024");
	do {
		printf("\n\nNumero de filas: ");
		scanf("%d", &filas);
		getchar();

		printf("\nNumero de columnas: ");
		scanf("%d", &columnas);
		getchar();
	} while ((filas*columnas > 1024) || filas <= 0 || columnas <= 0);

	// Saca el tama�o del array
	printf("\nNumero de elementos: %d", filas*columnas);

	// Dimensiones del kernel
	dim3 Nbloques(1);
	dim3 hilosB(columnas, filas);

	// Reserva en el host
	hst_matriz = (int*)malloc(filas*columnas * sizeof(int));
	hst_matriz_resultado = (int*)malloc(filas*columnas * sizeof(int));

	// Reserva en el device
	cudaMalloc( &dev_matriz, filas*columnas * sizeof(int));
	cudaMalloc( &dev_matriz_resultado, filas*columnas * sizeof(int));

	// Insertamos valores random en la matriz
	srand((int)time(NULL));
	for (int i = 0; i < filas*columnas; i++)
	{
		hst_matriz[i] = RAN_MIN + rand() % RAN_MAX;
	}

	// Pasamos el array al device y le damos la vuelta
	cudaMemcpy(dev_matriz, hst_matriz, filas*columnas * sizeof(int), cudaMemcpyHostToDevice);
	mueveFila <<<Nbloques, hilosB>>>(dev_matriz, dev_matriz_resultado, filas);

	// Check de errores
	cudaDeviceSynchronize();
	cudaError_t error = cudaGetLastError();
	if (error != cudaSuccess)
	{
		fprintf(stderr, "ERROR: %s\n", cudaGetErrorString(error));
		exit(-1);
	}

	// Pasamos el resultado a la cpu
	cudaMemcpy(hst_matriz_resultado, dev_matriz_resultado, filas*columnas * sizeof(int), cudaMemcpyDeviceToHost);

	// Muestra contenido de arrays y resultado
	printf("\n\nMatriz: \n");
	printf("*****************\n");

	for (int i = 0; i < filas; i++) {
		for(int j = 0; j < columnas; j++) {
			printf("%d ", hst_matriz[i+j*columnas]);
		}
		printf("\n");
	}

	printf("\n\nMatriz Resultado: \n");
	printf("*********************\n");

	for (int i = 0; i < filas; i++) {
		for(int j = 0; j < columnas; j++) {
			printf("%d ", hst_matriz_resultado[i+j*columnas]);
		}
		printf("\n");
	}
	
	// Marca de final
	cudaEventRecord(stop, 0);

	// Sincronizacion CPU-GPU
	cudaEventSynchronize(stop);

	// Calculo del tiempo
	float tiempoTrans;
	cudaEventElapsedTime(&tiempoTrans, start, stop);
	printf("\n\n> Tiempo de ejecuccion: %f ms\n", tiempoTrans);

	// Liberacion de recursos
	free(hst_matriz);
	free(hst_matriz_resultado);
	cudaFree(dev_matriz);
	cudaFree(dev_matriz_resultado);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);

	// Salida
	time_t fecha;
	time(&fecha);
	printf("\n\n***************************************************\n");
	printf("Programa ejecutado el: %s\n", ctime(&fecha));
	printf("<pulsa [INTRO] para finalizar>");
	getchar();
	return 0;
}
