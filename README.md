# Mapping Stylesheets #

## Background ##

This stylesheet writes stylesheets — it is intended to help in situations where directly writing XSLT would lead to a large number of very similar stylesheets. The original problem space was conversion from Microsoft WordML to any of several XML formats.  Transformations from WordML tend to be highly repetitive. This approach is the result of some years of refactoring and is part of a process that operates as follows:

1. Transform WordML to a _soup_ of elements in the output space; these elements are in the correct namespace, schema, etc but no attempt is made to generate valid output. The Word styles are copied to attributes on the output elements.
2. Transform paragraphs (WordML is basically all paragraph) into more specific elements by using the Word styles to determine the new element. This step is driven by the mapping tools and can add hints to be used by later steps
3. Progressively improve the content by using a sequence of transformations which progressively improve the content.  These steps can include structure creation, grouping (including list creation) and so on. 
4. Final cleanup — remove any artefacts of the conversion process.

## The mapping configuration ##

The mapping tools are driven by an XML file which describes the conversions. The mapping file is in the namespace `http://www.corbas.co.uk/ns/transforms/map` and must validate against `mapping.rng`. 

**NOTE**: the mapping namespace is omitted from the examples below for brevity.

The mapping file is deliberately simple. The primary simplification is to do with namespaces. A map document assumes that the input and output elements are in the same namespace. Only one namespace can be referenced per mapping document. Multiple mapping documents 

### `map` element ###

The root element is the `map`. This contains a sequence of `mapping` elements. The overall reach of the mapping is defined by attributes on the `map` element:

`ns`
: 	The namespace of both input and output elements

`source-element`
:	The element to be mapped; this can be overridden on the `mapping` element.

`source-attribute`
:	The attribute (on the source element) which will contain the value that the transformation is driven from. This can be overridden on the `mapping` element.

`target-attribute`
:	An optional default for an output attribute. Individual mapping elements can define a `target-attribute-value` to be placed in this attribute.

### `mapping` elements ###

The individual transformations are driven by `mapping` elements. `mapping` elements contain the values which drive the transformations and the elements to be output instead.

The following attributes are defined (explained in more detail below):

`source-value`
: 	The `source-value` attribute provides an attribute value (usually this would be a Word style name) which can be used to define a XSLT template match.

`source-value-prefix`
: 	This attribute fulfils the same role as `source-value` but allows an initial substring match instead of an exact match.

`source-value-suffix`
: 	This attribute fulfils the same role as `source-value` but allows an final substring match instead of an exact match.

`suppress`
:	Whatever any other attributes are set to, a `mapping`  element with the `suppress` attribute set to true lead to the matching input node being suppressed in the output.

`target-element`
:	The `target-element` attribute enables the conversion of the input element into a different element in the same namespace. The value of the attribute can be a space separated list of element names. In this is the case multiple nested elements will be created in the output.

`target-attribute`
:	An optional output attribute name. The value of `target-attribute-value` is stored in the attribute if provided. 

`target-attribute-value`
:	If the `target-attribute` and this attribute are provided the stylesheet will generate an attribute with the given name and value in the output

`source-element`
:	The element to be mapped.

`source-attribute`
:	The attribute (on the source element) which will contain the value that the transformation is driven from. 

### How it all works ###
Each `mapping`  element is used to generate an `xsl:template` statement. The `source-element`, `source-attribute` and `source-value` attributes are combined to create the template match:

```xml
<mapping source-element="p" source-attribute="class" 
  source-value="Heading1"/>
```

creating the following template skeleton:

```xml
<xsl:template match="p[@class = 'Heading1']">
…
</xsl:template>
```

The `target-element`  attribute is used to create one or output elements. Multiple elements will be created as nested elements. The attributes of the input element will be copied to each of these. Any element with a local name of `id` will be copied to the outermost element only.

For example, if the input element was as follows:

```xml
<p xml:id="n1" class="Heading1">This is a test</p>
```

and the mapping was as follows:

```
<mapping source-element="p" source-attribute="class" 
  source-value="Heading1" target-element="h1"/>
```

the output of the generated transformation would be

```
<h1 class="Heading1" xml:id="n1">This is a test</h1>
```

However, if the mapping was
```xml
<mapping source-element="p" source-attribute="class" 
  source-value="Heading1" 
  target-element="div h1"/>
```

the output would be:

```
<div xml:id="n1" class="Heading1">
  <h1 class="Heading1">This is a test</h1>
</div>
```

For reference, the generated template would be:

```xml
<xsl:template match="p[@class = 'Heading1']">
  <div>
    <xsl:apply-templates select="@*[local-name() = 'id']"/>
    <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
    <h1>
      <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
      <xsl:apply-templates select="node()"/>
    </h1>
  </div>
</xsl:template>
```

The `target-attribute` and `target-attribute-value` attributes simply generate a new attribute/value pair on the top level output element. If the `target-attribute` matches the `source-attribute` the source attribute's value will not be copied to the output but will be replaced with the value stored in `target-attribute-value`.

```xml
<mapping source-element="p" source-attribute="class" 
  source-value="Heading1" 
  target-attribute="data-mapped"
  target-attribute-value="map-step-1"
  target-element="h1"/>
```

The resulting output given our earlier input would be:

```xml
<h1 xml:id="n1" class="Heading1" 
  data-mapped="map-step-1">This is a test</h1>
```

There are two other attributes which can be written during the mapping process. The first, `hint` is simply copied to the output node as a namespace attribute (`hint` in `http://www.corbas.co.uk/ns/transforms/map`). This is intended for use as a temporary attribute during transformation to provide information for later steps:

```xml
<map source-element="p" source-attribute="class">
	<mapping source-value="NumPara" 
	hint="numbered-list" target-element="li"/>
</map>
```

with the following input

```xml
<p class="NumPara">Something in a numbered paragraph</p>
```

could generate the following final output:

```xml
<li map:hint="numbered-list" class="NumPara">
  Something in a numbered paragraph</li>
```

providing a simple way to gather all numeric list items and wrap them later.

Finally, the `heading-level` attribute can be used to indicate the heading priority for later insertion of structure based on headings (see the `insert-sections.xsl` file for an example)

```xml
<map source-element="p" source-attribute="class">
  <mapping source-value="Heading1" 
    heading-level="1" target-element="h1"/>
  <mapping source-value="Heading2" 
    heading-level="2" target-element="h1"/>
</map>
```

with the following input

```xml
<p class="Heading1">My Important Document</p>
<p class="Heading2">By Me</p>
```

could generate the following final output:

```xml
<h1 class="Heading1" map:level="1">My Important Document</h1>
<h1 class="Heading2" map:level="2">By Me</h1>
```

