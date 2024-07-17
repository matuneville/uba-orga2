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
static inline void zero_page(paddr_t addr){
  kmemset((void*)addr, 0x00, PAGE_SIZE);
}


void mmu_init(void) {
}


/**
 * mmu_next_free_kernel_page devuelve la dirección física de la próxima página de kernel disponible. 
 * Las páginas se obtienen en forma incremental, siendo la primera: next_free_kernel_page
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de kernel
 */
paddr_t mmu_next_free_kernel_page(void) {
    next_free_kernel_page += PAGE_SIZE;
    return (next_free_kernel_page - PAGE_SIZE);
}

/**
 * mmu_next_free_user_page devuelve la dirección de la próxima página de usuarix disponible
 * @return devuelve la dirección de memoria de comienzo de la próxima página libre de usuarix
 */
paddr_t mmu_next_free_user_page(void) {
    next_free_user_page += PAGE_SIZE;
    return (next_free_user_page - PAGE_SIZE);
}

/**
 * mmu_init_kernel_dir inicializa las estructuras de paginación vinculadas al kernel y
 * realiza el identity mapping
 * @return devuelve la dirección de memoria de la página donde se encuentra el directorio
 * de páginas usado por el kernel
 */
paddr_t mmu_init_kernel_dir(void) {
    // Escribo el entry del Dir que mapea a la Page Table del Kernel
    struct pd_entry_t KERNEL_PDE = {.pt = KERNEL_PAGE_TABLE_0 >> 12, .attrs = MMU_P | MMU_W};
    kpd[0] = KERNEL_PDE;

    // Escribo en la Page Table los entries a cada pagina fisica
    // mapeo kernel de 0x000000 a 0x400000 (donde 0x400000 = 1024 * 4096), las 1024 paginas del Page Table
    for(int i = 0; i < 1024; i++){
        struct pt_entry_t KERNEL_PTE = {.page = (PAGE_SIZE * i) >> 12, .attrs = MMU_P | MMU_W};
        kpt[i] = KERNEL_PTE;
    }
    return kpd;
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
  // 1. agregar entry al Page Directory Table mapeandolo al Page Table
  uint32_t dir = VIRT_PAGE_DIR(virt);
  uint32_t table = VIRT_PAGE_TABLE(virt);
  uint32_t offset = VIRT_PAGE_OFFSET(virt);

  pd_entry_t* PDT_Base = CR3_TO_PAGE_DIR(cr3);

  // 2. agregar entry al Page Table y mapearlo a la pagina fisica

  if (!(PDT_Base[dir].attrs & MMU_P)){
    paddr_t new_PTAddress = mmu_next_free_kernel_page(); // obtenemos una pagina para nueva Page Table
    zero_page(new_PTAddress);
    PDT_Base[dir].pt = MMU_ENTRY_PADDR(new_PTAddress);
  }
  PDT_Base[dir].attrs |= attrs | MMU_P; // me quedo con los attrs MENOS restrictivos

  pt_entry_t* PT_Base = MMU_ENTRY_PADDR(PDT_Base[dir].pt);

  PT_Base[table].page = MMU_ENTRY_PADDR(phy);
  PT_Base[table].attrs = attrs;

  lcr3(cr3);
  tlbflush();
}


/**
 * mmu_unmap_page elimina la entrada vinculada a la dirección virt en la tabla de páginas correspondiente
 * @param virt la dirección virtual que se ha de desvincular
 * @return la dirección física de la página desvinculada
 */
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt) {
  uint32_t dir = VIRT_PAGE_DIR(virt);
  uint32_t table = VIRT_PAGE_TABLE(virt);
  uint32_t offset = VIRT_PAGE_OFFSET(virt);

  pd_entry_t* PDT_Base = CR3_TO_PAGE_DIR(cr3);

  pt_entry_t* PT_Base = MMU_ENTRY_PADDR(PDT_Base[dir].pt);

  if(PT_Base[table].attrs & MMU_P)
    PT_Base[table].attrs &= 0xFFE; // seteo bit P en 0
  
  return MMU_ENTRY_PADDR(PT_Base[table].page);
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
  /*
  vaddr A -> paddr src
  escribir en vaddr A -> escribir en paddr src
  */

  uint32_t cr3 = rcr3();
  mmu_map_page(cr3, DST_VIRT_PAGE, dst_addr, MMU_W | MMU_P);
  mmu_map_page(cr3, SRC_VIRT_PAGE, src_addr, MMU_P);

  uint32_t* dst =  (uint32_t*) DST_VIRT_PAGE;
  uint32_t* src =  (uint32_t*) SRC_VIRT_PAGE;
  
  for(int i=0; i < 1024; i++){ // 4KB = 4096B = 1024*4B (4B el tamaño que escribo)
    dst[i] = src[i];
  }

  mmu_unmap_page(cr3, DST_VIRT_PAGE);
  mmu_unmap_page(cr3, SRC_VIRT_PAGE);
}

 /**
 * mmu_init_task_dir inicializa las estructuras de paginación vinculadas a una tarea cuyo código se encuentra en la dirección phy_start
 * @pararm phy_start es la dirección donde comienzan las dos páginas de código de la tarea asociada a esta llamadA
 * @return el contenido que se ha de cargar en un registro CR3 para la tarea asociada a esta llamada
 */
paddr_t mmu_init_task_dir(paddr_t phy_start) {
  pd_entry_t* PDT_Base = mmu_next_free_kernel_page();
  zero_page(PDT_Base);

  // pido pagina para mapear a kernel
  pt_entry_t* PT_Kernel_Base = mmu_next_free_kernel_page(); 
  copy_page(PT_Kernel_Base, (paddr_t)kpt); // hago otra tabla de kernel

  PDT_Base[0].pt = (uint32_t)PT_Kernel_Base >> 12; // esto funciona porque en kernel es identity maping
  PDT_Base[0].attrs = MMU_P | MMU_W; // mapea a tabla kernel restringiendo a supervisor

  // pido pagina para pt de tarea           (no es necesario esto, lo hace map_page)
  //pt_entry_t* PT_Base = mmu_next_free_kernel_page();
  //PDT_Base[VIRT_PAGE_DIR(TASK_CODE_VIRTUAL)].pt = (uint32_t)PT_Base>>12;
  //PDT_Base[VIRT_PAGE_DIR(TASK_CODE_VIRTUAL)].attrs = MMU_P | MMU_W | MMU_U; 

  // mapeo paginas de codigo nivel user
  // el mmu_map_page no va a crear pagina nueva de kernel para la tabla, ya que la mapeamos arriba de pd a pt
  mmu_map_page(PDT_Base, TASK_CODE_VIRTUAL, phy_start, MMU_P | MMU_U);
  mmu_map_page(PDT_Base, TASK_CODE_VIRTUAL+PAGE_SIZE, phy_start+PAGE_SIZE, MMU_P | MMU_U);

  //Pido una pagina para la pila de nivel 3 (debe ser user)
  paddr_t pila_phy = mmu_next_free_user_page();
  mmu_map_page(PDT_Base, TASK_STACK_BASE+TASK_CODE_PAGES*PAGE_SIZE, pila_phy, MMU_P | MMU_U | MMU_W); 

  //Mapeo el espacio compartido
  mmu_map_page(PDT_Base, TASK_SHARED_PAGE, SHARED, MMU_P | MMU_U);

  return PDT_Base; // retorno cr3 con attrs 0s
}

// COMPLETAR: devuelve true si se atendió el page fault y puede continuar la ejecución 
// y false si no se pudo atender
bool page_fault_handler(vaddr_t virt) {
  print("Atendiendo page fault... sape", 0, 0, C_FG_WHITE | C_BG_BLACK);
  // Chequeemos si el acceso fue dentro del area on-demand
  // En caso de que si, mapear la pagina
  if(ON_DEMAND_MEM_START_VIRTUAL <= virt && virt <= ON_DEMAND_MEM_END_VIRTUAL){
    uint32_t dir = VIRT_PAGE_DIR(virt);
    uint32_t table = VIRT_PAGE_TABLE(virt);
    uint32_t offset = VIRT_PAGE_OFFSET(virt);

    uint32_t cr3 = rcr3();

    pd_entry_t PDEntry = ((pd_entry_t*)CR3_TO_PAGE_DIR(cr3))[dir];
    
    if(PDEntry.attrs & MMU_P){
      pt_entry_t PTEntry = ((pt_entry_t*)MMU_ENTRY_PADDR(PDEntry.pt))[table];
      if (!(PTEntry.attrs & MMU_P)){
        mmu_map_page(cr3, virt, ON_DEMAND_MEM_START_PHYSICAL, MMU_U | MMU_W | MMU_P);
      }
    }
    else
      mmu_map_page(cr3, virt, ON_DEMAND_MEM_START_PHYSICAL, MMU_U | MMU_W | MMU_P);
    
    return 1;
  }
  return 0;
}