#include <stdio.h>
#include <stdlib.h>

struct node{
	int dst;
	struct node* next;
};

struct list{
	struct node *head;
};

struct graph{
	int n;
	struct list* set;
};



extern __managed__ struct node* newnode;
extern __managed__ struct graph* newgraph;

/*struct node* new_node(int dst){
	cudaMallocManaged(&newnode, sizeof(struct node), (unsigned int)cudaMemAttachGlobal);
	cudaMemAdvise(newnode, sizeof(struct node), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);
	newnode -> dst = dst;
	newnode -> next = NULL;

	return newnode;
}*/

void new_node(int dst){
	cudaMallocManaged(&newnode, sizeof(struct node), (unsigned int)cudaMemAttachGlobal);
	cudaMemAdvise(newnode, sizeof(struct node), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);
	newnode -> dst = dst;
	newnode -> next = NULL;

}

/*struct graph* new_graph(int n){
	
	cudaMallocManaged(&newgraph, sizeof(struct graph), (unsigned int)cudaMemAttachGlobal);
	cudaMemAdvise(newgraph, sizeof(struct graph), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

	newgraph -> n = n;
	
	newgraph -> set = (struct list*)malloc(n * sizeof(struct list)) ;

	int i;
	for(i=0;i<n;i++)
		newgraph->set[i].head = NULL;

	return newgraph;

}*/

void new_graph(int n){
	
	cudaMallocManaged(&newgraph, sizeof(struct graph), (unsigned int)cudaMemAttachGlobal);
	cudaMemAdvise(newgraph, sizeof(struct graph), cudaMemAdviseSetAccessedBy, cudaCpuDeviceId);

	newgraph -> n = n;
	
	newgraph -> set = (struct list*)malloc(n * sizeof(struct list)) ;

	int i;
	for(i=0;i<n;i++)
		newgraph->set[i].head = NULL;


}

/*void addEdge(struct graph* gph, int src, int dst){
	struct node* newnode = new_node(dst);
	newnode->next = gph->set[src].head;
	gph->set[src].head = newnode;

	newnode = new_node(src);
        newnode->next = gph->set[dst].head;
        gph->set[dst].head = newnode;
}*/

void addEdge( int src, int dst){
	new_node(dst);
	newnode->next = newgraph->set[src].head;
	newgraph->set[src].head = newnode;

	new_node(src);
        newnode->next = newgraph->set[dst].head;
        newgraph->set[dst].head = newnode;
}


__global__ void count(int* auth_num) {
    
    // Calculate the index in the vector for the thread using the internal variables
    int tid = blockIdx.x * blockDim.x + threadIdx.x; // HERE
    
    // This if statement is added in case we have more threads executing
    // Than number of elements in the vectors. How can this help?

        int co_auth = 0; 
        struct node* vert_node = newgraph->set[tid].head; 
        //printf("\n Adjacency list of vertex %d\n head ", v); 
        /*while (vert_node) 
        { 
            //printf("-> %d", vert_node->dst); 
            vert_node = vert_node->next;
	    co_auth++; 
        }*/
        auth_num[tid] = vert_node->dst;
    

}


//Utility functions to read the file
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

int compare (const void * a, const void * b)
{
  return ( *(int*)b - *(int*)a );
}


int main() { 

    FILE *fp;
    char str[200];
    const char* file = "dblp-co-authors.txt";
 
    fp = fopen(file, "r");
    if (fp == NULL){
        printf("Could not open file %s",file);
        return 1;
    }
    
	int vert;
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    fgets(str, 200, fp);
	    //printf("%s", str);
	    vert = get_vert(str);
	    long src, dst;
	    new_graph(vert);
	//struct graph* gph = new_graph(vert); 
	    while (fgets(str, 200, fp) != NULL){
		//printf("%s", str);
		src = get_src(str);
		dst = get_dst(str);
		addEdge(src,dst);
	    }
   

    printf("Graph Created....\n");

    
    /*for(int v=0;v<10;v++){
        struct node* vert_node = newgraph->set[v].head; 
	checkauth=0;
        printf("\n Adjacency list of vertex %d\n head ", v); 
        while (vert_node) 
        { 
            printf("-> %d", vert_node->dst); 
            vert_node = vert_node->next;
        }
     }*/


    // Set GPU Variables based on input arguments
    int graph_size = newgraph->n;
    int block_size  = 512;
    int grid_size   = ((graph_size-1)/block_size) + 1;

    // Set device that we will use for our cuda code
    cudaSetDevice(0);
        
    // Time Variables
    cudaEvent_t start, stop;
    float time;
    cudaEventCreate (&start);
    cudaEventCreate (&stop);

    // Input Arrays and variables
    int *auth_num    = new int [graph_size];

    // Pointers in GPU memory
    int *auth_num_gpu;
    struct graph *gph_gpu;

    int actual_size = 1049866  * sizeof(struct graph);
    int num_size = graph_size * sizeof(int);

    // allocate the memory on the GPU
    //cudaMalloc(&gph_gpu, actual_size);
    //cudaMalloc(&auth_num_gpu, num_size);

    // copy the arrays 'a' and 'b' to the GPU
    //cudaMemcpy(gph_gpu,gph,actual_size,cudaMemcpyHostToDevice);

    //
    // GPU Calculation
    ////////////////////////

    printf("Counting....\n");

    cudaEventRecord(start,0);

    // call the kernel
    //count<<<grid_size,block_size>>>(auth_num_gpu);
    
    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&time, start, stop);
    //printf("\tParallel Job Time: %.2f ms\n", time);

    // copy the array 'c' back from the GPU to the CPU
    // HERE (there's one more at the end, don't miss it!)
    //cudaMemcpy(auth_num,auth_num_gpu,num_size,cudaMemcpyDeviceToHost);
    
    /*for(int i=0;i<graph_size;i++)
	printf("Authors: %d\n",auth_num[i]);*/
   

    // free CPU data
    free (newgraph);
    free (auth_num);

    // free the memory allocated on the GPU
    // HERE
    //cudaFree(auth_num_gpu);

    return 0;
}

