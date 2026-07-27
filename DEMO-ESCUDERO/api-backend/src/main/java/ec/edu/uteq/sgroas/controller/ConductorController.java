package ec.edu.uteq.sgroas.controller;

import ec.edu.uteq.sgroas.dto.ConductorRequest;
import ec.edu.uteq.sgroas.dto.ConductorResponse;
import ec.edu.uteq.sgroas.service.ConductorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/conductores")
@RequiredArgsConstructor
public class ConductorController {

    private final ConductorService conductorService;

    @GetMapping
    public ResponseEntity<Page<ConductorResponse>> listar(
            @PageableDefault(size = 10, sort = "id") Pageable pageable
    ) {
        return ResponseEntity.ok(conductorService.listar(pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ConductorResponse> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(conductorService.buscarPorId(id));
    }

    @PostMapping
    public ResponseEntity<ConductorResponse> crear(
            @Valid @RequestBody ConductorRequest request
    ) {
        ConductorResponse response = conductorService.crear(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ConductorResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody ConductorRequest request
    ) {
        return ResponseEntity.ok(conductorService.actualizar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desactivar(@PathVariable Long id) {
        conductorService.desactivar(id);
        return ResponseEntity.noContent().build();
    }
}