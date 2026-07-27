package com.biopet.config;

import com.biopet.entity.Mascota;
import com.biopet.entity.Rol;
import com.biopet.entity.Usuario;
import com.biopet.repository.MascotaRepository;
import com.biopet.repository.UsuarioRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;

/**
 * Carga datos de demostracion al arrancar el backend.
 *
 * Es IDEMPOTENTE: antes de crear cualquier registro comprueba si ya existe
 * (por email en usuarios, por conteo de mascotas). Por eso reiniciar el
 * contenedor del backend NO duplica el administrador ni las mascotas.
 */
@Configuration
public class DataInitializer {

    private static final String ADMIN_EMAIL = "admin@biopet.ec";
    private static final String ADMIN_PASSWORD = "Admin123*";

    @Bean
    CommandLineRunner seedDemo(UsuarioRepository usuarioRepository,
                                MascotaRepository mascotaRepository,
                                PasswordEncoder encoder) {
        return args -> {
            // 1) Usuario administrador de demostracion (idempotente por email)
            Usuario admin = usuarioRepository.findByEmail(ADMIN_EMAIL).orElseGet(() ->
                    usuarioRepository.save(Usuario.builder()
                            .nombre("Administrador BIOPET")
                            .email(ADMIN_EMAIL)
                            .passwordHash(encoder.encode(ADMIN_PASSWORD))
                            .rol(Rol.ROLE_ADMIN)
                            .activo(true)
                            .build())
            );

            // 2) Mascotas iniciales (idempotente: solo se crean si la tabla
            //    todavia esta vacia, para que el GET muestre datos desde el
            //    inicio sin duplicarse en reinicios posteriores)
            if (mascotaRepository.count() == 0) {
                mascotaRepository.save(Mascota.builder()
                        .duenio(admin)
                        .nombre("Luna")
                        .especie("Perro")
                        .raza("Labrador")
                        .fechaNacimiento(LocalDate.of(2022, 5, 10))
                        .activo(true)
                        .build());

                mascotaRepository.save(Mascota.builder()
                        .duenio(admin)
                        .nombre("Michi")
                        .especie("Gato")
                        .raza("Siames")
                        .fechaNacimiento(LocalDate.of(2021, 3, 2))
                        .activo(true)
                        .build());

                mascotaRepository.save(Mascota.builder()
                        .duenio(admin)
                        .nombre("Rocky")
                        .especie("Perro")
                        .raza("Bulldog Frances")
                        .fechaNacimiento(LocalDate.of(2023, 8, 21))
                        .activo(true)
                        .build());
            }
        };
    }
}
