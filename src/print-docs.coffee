minispade.require "pathology"
# puts = (arg) -> console.log JSON.stringify(arg)

classes =
  "Pathology.Object": {}

for klass in Pathology.Object.descendants
  ancestors = (ancestor.toString() for ancestor in klass.ancestors)
  instanceMethods = []
  classMethods = []

  for method in klass.classMethods or []
    continue unless method = klass.classMethod(method)
    classMethods.push method

  for method in klass.instanceMethods or []
    continue unless method = klass.instanceMethod(method)
    instanceMethods.push method

  classes[klass] = {ancestors, instanceMethods, classMethods}

console.log JSON.stringify classes
