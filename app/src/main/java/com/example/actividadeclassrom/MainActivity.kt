package com.example.actividadeclassrom

import android.os.Bundle
import android.view.LayoutInflater
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.actividadeclassrom.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var dbHelper: DBHelperAlumno
    private lateinit var adapter: AlumnoAdapter
    private var listaAlumnos = listOf<Alumno>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        dbHelper = DBHelperAlumno(this)

        setupRecyclerView()

        binding.fabAgregar.setOnClickListener {
            mostrarDialogoAlumno(null)
        }

        cargarAlumnos()
    }

    private fun setupRecyclerView() {
        adapter = AlumnoAdapter(
            listaAlumnos = listaAlumnos,
            onEditClick = { alumno -> mostrarDialogoAlumno(alumno) },
            onDeleteClick = { alumno -> confirmarEliminacion(alumno) }
        )
        binding.rvAlumnos.layoutManager = LinearLayoutManager(this)
        binding.rvAlumnos.adapter = adapter
    }

    private fun cargarAlumnos() {
        listaAlumnos = dbHelper.obtenerAlumnos()
        adapter.actualizarLista(listaAlumnos)
    }

    private fun mostrarDialogoAlumno(alumnoExistente: Alumno?) {
        val builder = AlertDialog.Builder(this)
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.dialog_alumno, null)

        val etNombre = view.findViewById<EditText>(R.id.etNombre)
        val etCuenta = view.findViewById<EditText>(R.id.etCuenta)
        val etCorreo = view.findViewById<EditText>(R.id.etCorreo)
        val etImagen = view.findViewById<EditText>(R.id.etImagen)

        if (alumnoExistente != null) {
            builder.setTitle("Editar Alumno")
            etNombre.setText(alumnoExistente.nombre)
            etCuenta.setText(alumnoExistente.cuenta)
            etCorreo.setText(alumnoExistente.correo)
            etImagen.setText(alumnoExistente.imagen)
        } else {
            builder.setTitle("Agregar Alumno")
        }

        builder.setView(view)
        builder.setPositiveButton("Guardar") { _, _ ->
            val nombre = etNombre.text.toString().trim()
            val cuenta = etCuenta.text.toString().trim()
            val correo = etCorreo.text.toString().trim()
            val imagen = etImagen.text.toString().trim()

            if (nombre.isNotEmpty() && cuenta.isNotEmpty() && correo.isNotEmpty()) {
                if (alumnoExistente == null) {
                    val nuevoAlumno = Alumno(nombre = nombre, cuenta = cuenta, correo = correo, imagen = imagen)
                    val exito = dbHelper.insertarAlumno(nuevoAlumno)
                    if (exito) {
                        Toast.makeText(this, "Alumno agregado", Toast.LENGTH_SHORT).show()
                        cargarAlumnos()
                    } else {
                        Toast.makeText(this, "Error al agregar alumno", Toast.LENGTH_SHORT).show()
                    }
                } else {
                    val alumnoActualizado = Alumno(id = alumnoExistente.id, nombre = nombre, cuenta = cuenta, correo = correo, imagen = imagen)
                    val filas = dbHelper.actualizarAlumno(alumnoActualizado)
                    if (filas > 0) {
                        Toast.makeText(this, "Alumno actualizado", Toast.LENGTH_SHORT).show()
                        cargarAlumnos()
                    } else {
                        Toast.makeText(this, "Error al actualizar alumno", Toast.LENGTH_SHORT).show()
                    }
                }
            } else {
                Toast.makeText(this, "Por favor complete los campos obligatorios", Toast.LENGTH_SHORT).show()
            }
        }
        builder.setNegativeButton("Cancelar", null)
        builder.create().show()
    }

    private fun confirmarEliminacion(alumno: Alumno) {
        AlertDialog.Builder(this)
            .setTitle("Eliminar Alumno")
            .setMessage("¿Estás seguro de que deseas eliminar a ${alumno.nombre}?")
            .setPositiveButton("Eliminar") { _, _ ->
                val filas = dbHelper.eliminarAlumno(alumno.id)
                if (filas > 0) {
                    Toast.makeText(this, "Alumno eliminado", Toast.LENGTH_SHORT).show()
                    cargarAlumnos()
                } else {
                    Toast.makeText(this, "Error al eliminar alumno", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }
}
