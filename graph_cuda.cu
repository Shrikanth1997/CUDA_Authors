#include <stdio.h>
#include <stdlib.h>

// Define maximum number of vertices in the graph
#define N 317080
#define EDGES 1049886

// Data structure to store graph
struct Graph {
	// An array of pointers to Node to represent adjacency list
	struct Node* head[N+1];
};

// A data structure to store adjacency list nodes of the graph
struct Node {
	int dest;
	struct Node* next;
};

// data structure to store graph edges
struct Edge {
	int src, dest;
};

struct author{
	int id;
	int co_auth;
};

extern __managed__ struct Graph * graph ;
extern __managed__ struct Node* newNode ;
extern __managed__ struct author *auth_list;
extern __managed__ int  *dist_auth;

// Function to create an adjacency list from specified edges
__host__ void createGraph(struct Graph* graph, struct Edge edges[], int n)
{
	unsigned i;

	// allocate memory for graph data structure
	//struct Graph* graph = (struct Graph*)malloc(sizeof(struct Graph));

	// initialize head pointer for all vertices
	for (i = 0; i < N+1; i++){
		graph->head[i] = NULL;

	}

	// add edges to the directed graph one by one
	for (i = 0; i < N+1; i++)
	{
		// get source and destination vertex
		int src = edges[i].src;
		int dest = edges[i].dest;

		// allocate new node of Adjacency List from src to dest
		cudaMallocManaged(&newNode, sizeof(struct Node), (unsigned int)cudaMemAttachGlobal);
       		cudaMemAdvise(newNode, sizeof(struct Node), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

		//struct Node* newNode = (struct Node*)malloc(sizeof(struct Node));
		newNode->dest = dest;

		// point new node to current head
		newNode->next = graph->head[src];

		// point head pointer to new node
		graph->head[src] = newNode;


		// 2. allocate new node of Adjacency List from dest to src
		cudaMallocManaged(&newNode, sizeof(struct Node), (unsigned int)cudaMemAttachGlobal);
       		cudaMemAdvise(newNode, sizeof(struct Node), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

		//newNode = (struct Node*)malloc(sizeof(struct Node));
		newNode->dest = src;

		// point new node to current head
		newNode->next = graph->head[dest];
	
		// change head pointer to point to the new node
		graph->head[dest] = newNode;
	}

	//return graph;
}

// Function to print adjacency list representation of graph
__global__ void countAuth(struct Graph* graph,struct author *auth_list, int n)
{
    	int tid = blockIdx.x * blockDim.x + threadIdx.x; // HERE
	int stride = blockDim.x * gridDim.x;


	int i;
	for (i = tid; i < n+1; i+=stride)
	{		
		//printf("%d\n", tid+i);
		int co_auth = 0;
		// print current vertex and all ts neighbors
		struct Node* ptr = graph->head[i];
		while (ptr != NULL)
		{
			//printf("(%d -> %d)\t", tid, ptr->dest);
			ptr = ptr->next;
			co_auth++;
		}
		auth_list[i].id = i;
		auth_list[i].co_auth = co_auth;
		//printf("\n");
	}
}


__global__ void distAuth(struct author *auth_list, int *dist_auth, int n)
{
	int tid = blockIdx.x * blockDim.x + threadIdx.x; // HERE
	int stride = blockDim.x * gridDim.x;


	int i;
	for (i = tid; i < n+1; i+=stride)
	{
		int idx = auth_list[i].co_auth;
		atomicAdd(dist_auth + idx, 1);
	}

}

long get_vert(char *str){
	char vert[20];
	int space_count = 0;
	int num_vert=0;	
	
	int i=0, j=0;
	while(str[i] != '\n'){
	
		if(str[i] == ' ')
			space_count++;
		if(space_count == 2){
			vert[j] = str[i];
			j++;
		}
		else if(space_count>2)	
			break;
		i++;
	}
	vert[j] = '\0';
    	//printf("%s\n", vert);
	num_vert = atoi(vert);
    	//printf("%d\n", num_vert);
	return num_vert;
	
}

int get_src(char *str){
	char s[20];
        int space_count = 0;
        int src=0;

        int i=0, j=0;
        while(str[i] != '\n'){

                if(str[i] == ' ')
                        space_count++;
                if(space_count == 0){
                        s[j] = str[i];
                        j++;
                }
		else
			break;
                i++;
        }
        s[j] = '\0';
        //printf("%s\n", s);
        src = atoi(s);
        //printf("%d\n", src);
        return src;
}

int get_dst(char *str){
	char d[20];
        int space_count = 0;
        int dst=0;

        int i=0, j=0;
        while(str[i] != '\n'){

                if(str[i] == ' ')
                        space_count++;
                if(space_count == 1){
                        d[j] = str[i];
                        j++;
                }
		else if(space_count>1)
			break;
                i++;
        }
        d[j] = '\0';
        //printf("%s\n", d);
        dst = atoi(d);
        //printf("%d\n", dst);
        return dst;
}


int comparator(const void *p, const void *q)  
{ 
    int l = ((struct author *)p)->co_auth; 
    int r = ((struct author *)q)->co_auth;  
    return (r - l); 
}

 
// Directed Graph Implementation in C
int main(void)
{
	// input array containing edges of the graph (as per above diagram)
	// (x, y) pair in the array represents an edge from x to y
	struct Edge *edges;
	edges = (struct Edge *) calloc (EDGES, sizeof(struct Edge));

    FILE *fp;
    char str[200];
    const char* file = "dblp-co-authors.txt";
    //const char* file = "test.txt";
 
    fp = fopen(file, "r");
    if (fp == NULL){
        printf("Could not open file %s",file);
        return 1;
    }
    
	int vert, i=0;
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    //printf("%s", str);
	    vert = get_vert(str);
	    long src, dst;
	    //new_graph(vert);
	//struct graph* gph = new_graph(vert); 
	    while (fgets(str, 200, fp) != NULL){
		//printf("%s", str);
		src = get_src(str);
		dst = get_dst(str);
		edges[i].src = src;
		edges[i].dest = dst;
		i++;
	    }
	
	printf("Edges copied....\n");

	// calculate number of edges
	int n = sizeof(edges)/sizeof(edges[0]);

	cudaMallocManaged(&graph, sizeof(struct Graph), (unsigned int)cudaMemAttachGlobal);
    	cudaMemAdvise(graph, sizeof(struct Graph), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

	createGraph(graph, edges, N);

	printf("Graph Created...\n");	


	int graph_size = N + 1;
    	int block_size  = 64;
    	int grid_size   = (graph_size + block_size - 1)/block_size;

    	// Set device that we will use for our cuda code
    	cudaSetDevice(0);
	

	cudaMallocManaged(&auth_list, graph_size * sizeof(struct author), (unsigned int)cudaMemAttachGlobal);
    	cudaMemAdvise(auth_list, graph_size * sizeof(struct author), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);
	
	// print adjacency list representation of graph
	countAuth<<<grid_size, block_size>>>(graph, auth_list, N);
	cudaDeviceSynchronize();

	/*for(i=0;i<N+1;i++){
		printf("Author %d : %d\n",auth_list[i].id, auth_list[i].co_auth);
	}*/

	qsort((void*)auth_list, graph_size, sizeof(struct author), comparator);

	/*for(i=0;i<N+1;i++){
		printf("Author %d : %d\n",auth_list[i].id, auth_list[i].co_auth);
	}*/

	int max = auth_list[0].co_auth;

	for(i=0;i<N+1;i++){
		if(auth_list[i].co_auth == max)
			printf("Author %d : %d\n",auth_list[i].id, auth_list[i].co_auth);
	}

 	
	cudaMallocManaged(&dist_auth, (max+1) * sizeof(int), (unsigned int)cudaMemAttachGlobal);
    	cudaMemAdvise(dist_auth, (max+1) * sizeof(int), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);
	cudaMemset(dist_auth, 0, (max+1)*sizeof(int));
	
	graph_size = N + 1;
    	block_size  = 64;
    	grid_size   = (graph_size + block_size - 1)/block_size;

	distAuth<<<grid_size, block_size>>>(auth_list, dist_auth, N);
	cudaDeviceSynchronize();
	
	
	for(i=0;i<=max;i++){
		printf("Dist %d: %d\n", i, dist_auth[i]);
	}

	return 0;
}
