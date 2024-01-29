import tkinter as tk
import threading

def crear_ventana():
    ventana = tk.Tk()
    ventana.title("Ventana en Negro")
    ventana.configure(bg="black")
    ventana.geometry("400x300+200+200")

    etiqueta = tk.Label(ventana, text="Hola, este es un texto de ejemplo.", fg="white", bg="black")
    etiqueta.place(x=100, y=50)

    ventana.mainloop()

# Crear un hilo para la ventana
hilo_ventana = threading.Thread(target=crear_ventana)

# Iniciar el hilo
hilo_ventana.start()

# Puedes realizar otras tareas aquí mientras la ventana está abierta en un hilo separado.
# ...

# Esperar a que el hilo de la ventana termine (opcional)
hilo_ventana.join()
