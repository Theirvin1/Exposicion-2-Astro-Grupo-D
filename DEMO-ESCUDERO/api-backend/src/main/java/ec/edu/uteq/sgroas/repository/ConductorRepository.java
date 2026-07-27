package ec.edu.uteq.sgroas.repository;

import ec.edu.uteq.sgroas.entity.Conductor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConductorRepository extends JpaRepository<Conductor, Long> {

    Page<Conductor> findByActivoTrue(Pageable pageable);

    boolean existsByCedula(String cedula);

    boolean existsByNumeroLicencia(String numeroLicencia);
}
