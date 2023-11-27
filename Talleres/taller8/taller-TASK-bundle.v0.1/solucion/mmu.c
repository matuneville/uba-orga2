/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "i386.h"
#include "defines.h"

#include "kassert.h"

static pd_entry_t* kpd = (pd_entry_t*)KERNEL_PAGE_DIR;    // array Page Table Entry para el Directory
static pt_entry_t* kpt = (pt_entry_t*)KERNEL_PAGE_TABLE_0;// array Page Entry para la Table

static const uint32_t identity_mapping_end = 0x003FFFFF;
static const uint32_t user_memory_pool_end = 0x02FFFFFF;

static paddr_t next_free_kernel_page = 0x100000;
static paddr_t next_free_user_page = 0x400000;

/**
 * kmemset asigna el valor c a un rango de memoria interpretado
 * como un rango de bytes de largo n que comienza en s
 * @param s es el puntero al comienzo del rango de memoria
 * @param c es el valor a asignar en cada byte de s[0..n-1]
 * @param n es el tamaño en bytes a asignar
 * @return devuelve el puntero al rango modificado (alias de s)
*/
static inline void* kmemset(void* s, int c, size_t n) {
  uint8_t* dst = (uint8_t*)s;
  for (size_t i = 0; i < n; i++) {
    dst[i] = c;
  }
  return dst;
}

/**
 * zero_page limpia el contenido de una página que comienza en addr
 * @param addr es la dirección del comienzo de la página a limpiar
*/
static inline void zero_page(paddr_t addr) {
  kmemset((void*)addr, 0x00, PAGE_SIZE);
}


void mmu_init(void) {}


/**
 * mmu_next_free_kernel_page devuelve la dirección física de la próxima página de kernel disponible. 
 * Las páginas se obtienen en forma incremental, siendo la primera: next_free_kernel_page
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de kernel
 */
paddr_t mmu_next_free_kernel_page(void){
  next_free_kernel_page += PAGE_SIZE;
  return (next_free_kernel_page-PAGE_SIZE);
}

/**
 * mmu_next_free_user_page devuelve la dirección de la próxima página de usuarix disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de usuarix
 */
paddr_t mmu_next_free_user_page(void){
    next_free_user_page += PAGE_SIZE;
    return (next_free_user_page-PAGE_SIZE);
}

/**
 * mmu_init_kernel_dir inicializa las estructuras de paginación vinculadas al kernel y
 * realiza el identity mapping
 * @return devuelve la dirección de memoria de la página donde se encuentra el directorio
 * de páginas usado por el kernel
 */
paddr_t mmu_init_kernel_dir(void) {
  // reservo el lugar para el Page Table Directory y para el Page Table
  zero_page(KERNEL_PAGE_DIR);     // 0x00025000 
  zero_page(KERNEL_PAGE_TABLE_0); // 0x00026000 
  
  // escribo el primer descriptor Table Entry
  kpd[0].pt = KERNEL_PAGE_TABLE_0 >> 12; // direccion de 32bits, me quedo con los 20 bits altos
  //0000 0010 0101 0000 0000 0000 0000 0000 >> 12 = 0000 0000 0000 0010 0101 0000 0000 0000 

  kpd[0].attrs = MMU_P + MMU_W;  // preguntar, que pasa con el resto de atributos?
  
  // ahora toca escribir en toda la tabla los Entrys a las páginas finales
  for(int i = 0; i < 1024; i++){
    kpt[i].page = i; 
    kpt[i].attrs = MMU_P + MMU_W;
  }

  return KERNEL_PAGE_DIR;
}

/**
 * mmu_map_page agrega las entradas necesarias a las estructuras de paginación de modo de que
 * la dirección virtual virt se traduzca en la dirección física phy con los atributos definidos en attrs
 * @param cr3 el contenido que se ha de cargar en un registro CR3 al realizar la traducción
 * @param virt la dirección virtual que se ha de traducir en phy
 * @param phy la dirección física que debe ser accedida (dirección de destino)
 * @param attrs los atributos a asignar en la entrada de la tabla de páginas
 */
void mmu_map_page(uint32_t cr3, vaddr_t virt, paddr_t phy, uint32_t attrs) {
  // obtenemos la base del Page Directory 
  pd_entry_t* page_dir = CR3_TO_PAGE_DIR(cr3);
  lcr3(cr3);

  uint32_t dir_index = VIRT_PAGE_DIR(virt);
  uint32_t table_index = VIRT_PAGE_TABLE(virt);
  
  if (!(page_dir[dir_index].attrs & MMU_P)) { // si el entry del directorio de páginas no está presente, viendo el bit P

    uint32_t new_page_table_address = mmu_next_free_kernel_page(); // agarro el numero del sgte page table
    page_dir[dir_index].pt = MMU_ENTRY_PADDR(new_page_table_address); // actualizo el entry del directory
    // aca abajo quiero los atributos menos restrictivos, y por las dudas agrego present
    page_dir[dir_index].attrs = (attrs | page_dir[dir_index].attrs) | MMU_P; 

    // ahora ya tengo la tabla nueva, accedo a ella y agrego la pagina
    pt_entry_t* new_page_table = MMU_ENTRY_PADDR(new_page_table_address);
    new_page_table[table_index].page = MMU_ENTRY_PADDR(phy);
    // aca abajo quiero los atributos mas restrictivos, y ṕor las dudas le pongo Present
    new_page_table[table_index].attrs = (attrs & (new_page_table[table_index].attrs)) | MMU_P; 
  }

  else{ // si está presente, agrego la nueva página en la tabla
    //pt_entry_t* page_table = page_dir[dir_index].pt << 12;
    pt_entry_t* page_table = MMU_ENTRY_PADDR(dir_index); // obtengo el Table Entry, es lo mismo que hacer page_dir[dir_index]
    page_table[table_index].page = MMU_ENTRY_PADDR(phy);
    // aca abajo quiero los atributos mas restrictivos, y ṕor las dudas le pongo Present
    page_table[table_index].attrs = (attrs & (page_table[table_index].attrs)) | MMU_P; 
  }

  tlbflush();
}

/**
 * mmu_unmap_page elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
 * @param virt la dirección virtual que se ha de desvincular
 * @return la dirección física de la página desvinculada
 */
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt) {
  // obtenemos la base del Page Directory 
  pd_entry_t* page_dir = CR3_TO_PAGE_DIR(cr3);

  uint32_t dir_index = VIRT_PAGE_DIR(virt);
  uint32_t table_index = VIRT_PAGE_TABLE(virt);
  uint32_t offset = VIRT_PAGE_OFFSET(virt);

  pd_entry_t page_table_entry = page_dir[dir_index];
  pt_entry_t* page_table = page_table_entry.pt;

  kmemset(&page_table[table_index], 0x00, sizeof(pt_entry_t));

  // ahora retorno la direc fisica, que seria la de los atributos en 0
  page_table_entry.attrs = 0;
  return page_table;
}

#define DST_VIRT_PAGE 0xA00000
#define SRC_VIRT_PAGE 0xB00000

/**
 * copy_page copia el contenido de la página física localizada en la dirección src_addr a la página física ubicada en dst_addr
 * @param dst_addr la dirección a cuya página queremos copiar el contenido
 * @param src_addr la dirección de la página cuyo contenido queremos copiar
 *
 * Esta función mapea ambas páginas a las direcciones SRC_VIRT_PAGE y DST_VIRT_PAGE, respectivamente, realiza
 * la copia y luego desmapea las páginas. Usar la función rcr3 definida en i386.h para obtener el cr3 actual
 */
void copy_page(paddr_t dst_addr, paddr_t src_addr) {
  uint32_t cr3 = rcr3();
  mmu_map_page(cr3,DST_VIRT_PAGE,dst_addr,MMU_W | MMU_P);
  mmu_map_page(cr3,SRC_VIRT_PAGE,src_addr,MMU_P);

  uint32_t* src = SRC_VIRT_PAGE;
  uint32_t* dst = DST_VIRT_PAGE;

  for(int i = 0; i < 1024; i++){
    dst[i] = src[i];
  }

  mmu_unmap_page(cr3,DST_VIRT_PAGE);
  mmu_unmap_page(cr3,SRC_VIRT_PAGE);
}

 /**
 * mmu_init_task_dir inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
 * @pararm phy_start es la dirección donde comienzan las dos páginas de código de la tarea asociada a esta llamada
 * @return el contenido que se ha de cargar en un registro CR3 para la tarea asociada a esta llamada
 */

paddr_t mmu_init_task_dir(paddr_t phy_start) {
  // identity maping
  paddr_t cr3 = mmu_next_free_kernel_page();
  zero_page(cr3);
  for(uint32_t i = 0; i< identity_mapping_end; i = i + PAGE_SIZE){
    mmu_map_page(cr3, i, i , MMU_W | MMU_P);
  }

  // mapeo del codigo, las dos paginas ya creadas
  mmu_map_page(cr3, TASK_CODE_VIRTUAL, phy_start, MMU_U | MMU_P);
  mmu_map_page(cr3, TASK_CODE_VIRTUAL + PAGE_SIZE, phy_start+PAGE_SIZE, MMU_U | MMU_P);

  // mapeo de la pila , esta la tengo que crear a nivel usuario
  paddr_t stack = mmu_next_free_user_page();
  mmu_map_page(cr3, TASK_STACK_BASE-PAGE_SIZE, stack, MMU_U | MMU_W | MMU_P);
  
  // mapeo de la memoria compartida 
  mmu_map_page(cr3, TASK_SHARED_PAGE, SHARED , MMU_U | MMU_P);

  return cr3;
}


// COMPLETAR: devuelve true si se atendió el page fault y puede continuar la ejecución 
// y false si no se pudo atender
bool page_fault_handler(vaddr_t virt) {
  print("Atendiendo page fault...", 0, 0, C_FG_WHITE | C_BG_BLACK);
  // Chequeemos si el acceso fue dentro del area on-demand
  if (virt>>12 == ON_DEMAND_MEM_START_VIRTUAL>>12) {
    mmu_map_page(rcr3(), virt, ON_DEMAND_MEM_START_PHYSICAL, MMU_P | MMU_U | MMU_W);
 
    return 1;
  }

  return 0;
}