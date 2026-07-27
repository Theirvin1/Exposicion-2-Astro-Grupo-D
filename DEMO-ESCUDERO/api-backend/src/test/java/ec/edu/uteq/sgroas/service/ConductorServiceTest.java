package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.ConductorRequest;
import ec.edu.uteq.sgroas.dto.ConductorResponse;
import ec.edu.uteq.sgroas.entity.Conductor;
import ec.edu.uteq.sgroas.entity.EstadoConductor;
import ec.edu.uteq.sgroas.repository.ConductorRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ConductorServiceTest {

    @Mock
    private ConductorRepository conductorRepository;

    @InjectMocks
    private ConductorService conductorService;

    @Test
    void crearConductorCorrectamente() {
        ConductorRequest request = new ConductorRequest(
                "Carlos Alberto",
                "Mendoza Vera",
                "1200000001",
                "LIC-001-2026",
                "E",
                LocalDate.of(2026, 7, 15),
                "0988888888",
                "carlos.mendoza@sgroas.com",
                "ACTIVO"
        );

        Conductor conductorGuardado = Conductor.builder()
                .id(1L)
                .nombres("Carlos Alberto")
                .apellidos("Mendoza Vera")
                .cedula("1200000001")
                .numeroLicencia("LIC-001-2026")
                .tipoLicencia("E")
                .fechaVencimientoLicencia(LocalDate.of(2026, 7, 15))
                .telefono("0988888888")
                .email("carlos.mendoza@sgroas.com")
                .estado(EstadoConductor.ACTIVO)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        when(conductorRepository.existsByCedula("1200000001"))
                .thenReturn(false);
        when(conductorRepository.existsByNumeroLicencia("LIC-001-2026"))
                .thenReturn(false);
        when(conductorRepository.save(any(Conductor.class)))
                .thenReturn(conductorGuardado);

        ConductorResponse response = conductorService.crear(request);

        assertNotNull(response);
        assertEquals(1L, response.id());
        assertEquals("Carlos Alberto", response.nombres());
        assertEquals("1200000001", response.cedula());
        assertEquals("ACTIVO", response.estado());
        verify(conductorRepository).save(any(Conductor.class));
    }

    @Test
    void crearConductorConCedulaDuplicadaDebeLanzarExcepcion() {
        ConductorRequest request = new ConductorRequest(
                "Carlos Alberto",
                "Mendoza Vera",
                "1200000001",
                "LIC-001-2026",
                "E",
                LocalDate.of(2026, 7, 15),
                "0988888888",
                "carlos.mendoza@sgroas.com",
                "ACTIVO"
        );

        when(conductorRepository.existsByCedula("1200000001"))
                .thenReturn(true);

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> conductorService.crear(request)
        );

        assertEquals("Ya existe un conductor con esa cedula", exception.getMessage());
        verify(conductorRepository, never()).save(any(Conductor.class));
    }

    @Test
    void buscarConductorPorIdCorrectamente() {
        Conductor conductor = Conductor.builder()
                .id(1L)
                .nombres("Carlos Alberto")
                .apellidos("Mendoza Vera")
                .cedula("1200000001")
                .numeroLicencia("LIC-001-2026")
                .tipoLicencia("E")
                .fechaVencimientoLicencia(LocalDate.now().plusDays(20))
                .telefono("0988888888")
                .email("carlos.mendoza@sgroas.com")
                .estado(EstadoConductor.ACTIVO)
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        when(conductorRepository.findById(1L))
                .thenReturn(Optional.of(conductor));

        ConductorResponse response = conductorService.buscarPorId(1L);

        assertNotNull(response);
        assertEquals(1L, response.id());
        assertEquals("Carlos Alberto", response.nombres());
        assertTrue(response.licenciaPorVencer());
    }
}
