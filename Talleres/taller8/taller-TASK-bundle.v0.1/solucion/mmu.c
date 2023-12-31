/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "i386.h"

#include "kassert.h"

static pd_entry_t* kpd = (pd_entry_t*)KERNEL_PAGE_DIR;
static pt_entry_t* kpt = (pt_entry_t*)KERNEL_PAGE_TABLE_0;

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
paddr_t mmu_next_free_kernel_page(void) {
  paddr_t new_page = next_free_kernel_page;
  next_free_kernel_page += PAGE_SIZE;
  return new_page;
}

/**
 * mmu_next_free_user_page devuelve la dirección de la próxima página de usuarix disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de usuarix
 */
paddr_t mmu_next_free_user_page(void) {
  paddr_t new_page = next_free_user_page;
  next_free_user_page += PAGE_SIZE;
  return new_page;
}

/**
 * mmu_init_kernel_dir inicializa las estructuras de paginación vinculadas al kernel y
 * realiza el identity mapping
 * @return devuelve la dirección de memoria de la página donde se encuentra el directorio
 * de páginas usado por el kernel
 */
paddr_t mmu_init_kernel_dir(void) {

  pd_entry_t* dir_kernel = (pd_entry_t*)0x25000;

  pt_entry_t* kernel_table = (pt_entry_t*)0x26000;

  zero_page(dir_kernel);
  zero_page(kernel_table);

  dir_kernel[0].attrs = (MMU_P | MMU_W);

  dir_kernel[0].pt = (KERNEL_PAGE_TABLE_0 >> 12);

  for (int i = 0; i < 1024; i++) {
    kernel_table[i].attrs = MMU_P | MMU_W;
    kernel_table[i].page  = i;
  }

  tlbflush();
  return dir_kernel;                                                  
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
  pd_entry_t* dir = CR3_TO_PAGE_DIR(cr3);
  uint32_t dir_index = VIRT_PAGE_DIR(virt);

  if ((dir[dir_index].attrs & MMU_P) == 0) {
    uint32_t new_page = mmu_next_free_kernel_page();

    zero_page(new_page);

    dir[dir_index].attrs = attrs | MMU_P | MMU_U | MMU_W;
    dir[dir_index].pt = new_page >> 12;
  }

  pt_entry_t* table = MMU_ENTRY_PADDR(dir[dir_index].pt);
  uint32_t table_index = VIRT_PAGE_TABLE(virt);

  table[table_index].attrs = attrs | MMU_P;
  table[table_index].page  = phy>>12;

  tlbflush();
}

/**
 * mmu_unmap_page elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
 * @param virt la dirección virtual que se ha de desvincular
 * @return la dirección física de la página desvinculada
 */
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt) {
  pd_entry_t* dir    = CR3_TO_PAGE_DIR(cr3);
  paddr_t dir_index = VIRT_PAGE_DIR(virt);

  pt_entry_t* table    = MMU_ENTRY_PADDR(dir[dir_index].pt); 
  paddr_t table_index = VIRT_PAGE_TABLE(virt);

  table[table_index].attrs = 0;
  paddr_t phy = MMU_ENTRY_PADDR(table[table_index].page);
  tlbflush();                                      
  return phy;
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
  uint32_t CR3 = rcr3();

  // mapeo phy a virt
  mmu_map_page(CR3, SRC_VIRT_PAGE, src_addr, MMU_P | MMU_W);  
  mmu_map_page(CR3, DST_VIRT_PAGE, dst_addr, MMU_P | MMU_W); 

  // pointer al inicio del page frame
  vaddr_t* src = SRC_VIRT_PAGE;
  vaddr_t* dst = DST_VIRT_PAGE;

  // aca se copia la pagina
  for (int i = 0; i < 1024; i++) {
    dst[i] = src[i];
  }

  // desmapeo phy a virt
  mmu_unmap_page(CR3, SRC_VIRT_PAGE); 
  mmu_unmap_page(CR3, DST_VIRT_PAGE);                        
}

 /**
 * mmu_init_task_dir inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
 * @pararm phy_start es la dirección donde comienzan las dos páginas de código de la tarea asociada a esta llamada
 * @return el contenido que se ha de cargar en un registro CR3 para la tarea asociada a esta llamada
 */
paddr_t mmu_init_task_dir(paddr_t phy_start) {
  paddr_t phy1 = phy_start;
  paddr_t phy2 = phy_start + PAGE_SIZE;
  paddr_t phy_pila = mmu_next_free_user_page(); // nueva posicion para la pila d ela tarea
  paddr_t phy_shared = SHARED; // dir fisica donde comienza memoria compartida

  vaddr_t vir1 = TASK_CODE_VIRTUAL;
  vaddr_t vir2 = TASK_CODE_VIRTUAL + PAGE_SIZE;
  vaddr_t vir_pila = TASK_STACK_BASE - PAGE_SIZE; // la pila empeiza en 0x08003000, pero hay q empezar desde arriba de la misma
  vaddr_t vir_shared = TASK_SHARED_PAGE;    

  pd_entry_t* cr3  = (pd_entry_t*)mmu_next_free_kernel_page(); // pido pagina del kernel para el CR3

  pd_entry_t* dir_kerneñ = (pd_entry_t*)KERNEL_PAGE_DIR;

  cr3[0] = dir_kerneñ[0];

  // aca uno todo
  mmu_map_page(cr3, vir1, phy1, MMU_P | MMU_U);
  mmu_map_page(cr3, vir2, phy2, MMU_P | MMU_U);
  mmu_map_page(cr3, vir_pila, phy_pila, MMU_P | MMU_U | MMU_W);
  mmu_map_page(cr3, vir_shared, phy_shared, MMU_P | MMU_U);

  return cr3;
}

// COMPLETAR: devuelve true si se atendió el page fault y puede continuar la ejecución 
// y false si no se pudo atender
bool page_fault_handler(vaddr_t virt) {
  print("Atendiendo page fault...", 0, 0, C_FG_WHITE | C_BG_BLACK);

  if (ON_DEMAND_MEM_START_VIRTUAL <= virt && virt <= ON_DEMAND_MEM_END_VIRTUAL) {
    uint32_t cr3 = rcr3();
    mmu_map_page(cr3, virt, ON_DEMAND_MEM_START_PHYSICAL, MMU_U | MMU_P | MMU_W);
    return true;
  }

  return false;  
}