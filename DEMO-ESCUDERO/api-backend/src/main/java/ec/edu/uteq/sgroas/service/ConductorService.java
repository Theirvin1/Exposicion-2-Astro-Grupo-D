package ec.edu.uteq.sgroas.service;

import ec.edu.uteq.sgroas.dto.ConductorRequest;
import ec.edu.uteq.sgroas.dto.ConductorResponse;
import ec.edu.uteq.sgroas.entity.Conductor;
import ec.edu.uteq.sgroas.entity.EstadoConductor;
import ec.edu.uteq.sgroas.repository.ConductorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class ConductorService {

    private final ConductorRepository conductorRepository;

    public Page<ConductorResponse> listar(Pageable pageable) {
        return conductorRepository.findByActivoTrue(pageable)
                .map(this::mapearAResponse);
    }

    public ConductorResponse buscarPorId(Long id) {
        Conductor conductor = obtenerConductorActivo(id);
        return mapearAResponse(conductor);
    }

    public ConductorResponse crear(ConductorRequest request) {
        validarCedulaDuplicada(request.cedula());
        validarLicenciaDuplicada(request.numeroLicencia());

        Conductor conductor = Conductor.builder()
                .nombres(request.nombres())
                .apellidos(request.apellidos())
                .cedula(request.cedula())
                .numeroLicencia(request.numeroLicencia())
                .tipoLicencia(request.tipoLicencia())
                .fechaVencimientoLicencia(request.fechaVencimientoLicencia())
                .telefono(request.telefono())
                .email(request.email())
                .estado(convertirEstado(request.estado()))
                .activo(true)
                .creadoEn(Instant.now())
                .actualizadoEn(Instant.now())
                .build();

        Conductor conductorGuardado = conductorRepository.save(conductor);
        return mapearAResponse(conductorGuardado);
    }

    public ConductorResponse actualizar(Long id, ConductorRequest request) {
        Conductor conductor = obtenerConductorActivo(id);

        if (!conductor.getCedula().equals(request.cedula())
                && conductorRepository.existsByCedula(request.cedula())) {
            throw new IllegalArgumentException("Ya existe un conductor con esa cedula");
        }

        if (!conductor.getNumeroLicencia().equals(request.numeroLicencia())
                && conductorRepository.existsByNumeroLicencia(request.numeroLicencia())) {
            throw new IllegalArgumentException("Ya existe un conductor con ese numero de licencia");
        }

        conductor.setNombres(request.nombres());
        conductor.setApellidos(request.apellidos());
        conductor.setCedula(request.cedula());
        conductor.setNumeroLicencia(request.numeroLicencia());
        conductor.setTipoLicencia(request.tipoLicencia());
        conductor.setFechaVencimientoLicencia(request.fechaVencimientoLicencia());
        conductor.setTelefono(request.telefono());
        conductor.setEmail(request.email());
        conductor.setEstado(convertirEstado(request.estado()));
        conductor.setActualizadoEn(Instant.now());

        Conductor conductorActualizado = conductorRepository.save(conductor);
        return mapearAResponse(conductorActualizado);
    }

    public void desactivar(Long id) {
        Conductor conductor = obtenerConductorActivo(id);
        conductor.setActivo(false);
        conductor.setEstado(EstadoConductor.INACTIVO);
        conductor.setActualizadoEn(Instant.now());
        conductorRepository.save(conductor);
    }

    private Conductor obtenerConductorActivo(Long id) {
        return conductorRepository.findById(id)
                .filter(Conductor::getActivo)
                .orElseThrow(() -> new IllegalArgumentException("Conductor no encontrado"));
    }

    private void validarCedulaDuplicada(String cedula) {
        if (conductorRepository.existsByCedula(cedula)) {
            throw new IllegalArgumentException("Ya existe un conductor con esa cedula");
        }
    }

    private void validarLicenciaDuplicada(String numeroLicencia) {
        if (conductorRepository.existsByNumeroLicencia(numeroLicencia)) {
            throw new IllegalArgumentException("Ya existe un conductor con ese numero de licencia");
        }
    }

    private EstadoConductor convertirEstado(String estado) {
        try {
            return EstadoConductor.valueOf(estado.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Estado de conductor no valido");
        }
    }

    private Boolean licenciaPorVencer(LocalDate fechaVencimiento) {
        LocalDate hoy = LocalDate.now();
        LocalDate limite = hoy.plusDays(30);

        return !fechaVencimiento.isBefore(hoy) && !fechaVencimiento.isAfter(limite);
    }

    private ConductorResponse mapearAResponse(Conductor conductor) {
        return new ConductorResponse(
                conductor.getId(),
                conductor.getNombres(),
                conductor.getApellidos(),
                conductor.getCedula(),
                conductor.getNumeroLicencia(),
                conductor.getTipoLicencia(),
                conductor.getFechaVencimientoLicencia(),
                conductor.getTelefono(),
                conductor.getEmail(),
                conductor.getEstado().name(),
                conductor.getActivo(),
                licenciaPorVencer(conductor.getFechaVencimientoLicencia()),
                conductor.getCreadoEn(),
                conductor.getActualizadoEn()
        );
    }
}
