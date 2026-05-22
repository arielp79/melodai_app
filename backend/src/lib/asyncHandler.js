/** Envuelve handlers async para que Express reciba errores y no cierre la conexión. */
export function asyncHandler(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}
